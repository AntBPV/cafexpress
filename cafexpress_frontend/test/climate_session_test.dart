import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:cafexpress_frontend/features/workspace/data/climate_repository.dart';
import 'package:cafexpress_frontend/features/workspace/domain/climate_trend.dart';
import 'package:cafexpress_frontend/features/workspace/domain/marketplace_models.dart';
import 'package:cafexpress_frontend/features/workspace/presentation/climate_controller.dart';
import 'package:cafexpress_frontend/features/workspace/presentation/climate_panel.dart';
import 'package:cafexpress_frontend/features/workspace/presentation/session_workspace.dart';
import 'package:cafexpress_frontend/features/auth/data/auth_repository.dart';

import 'sprint2_workspace_test.dart' as fixtures;

ClimateReading reading({bool falling = false}) => ClimateReading(
  origin: 'Pasto, Colombia',
  products: [fixtures.productModel()],
  temperature: falling ? 22 : 14,
  meanTemperature: 21,
  rain: 4,
  falling: falling,
  checkedAt: DateTime(2026, 11, 8),
);
ClimateSnapshot snapshot({bool falling = false}) =>
    ClimateSnapshot(readings: [reading(falling: falling)]);

void main() {
  test('la regla general usa temperatura y lluvia con límites incluidos', () {
    const rules = ClimateRules();
    expect(rules.falling(18, 24, 2), isTrue);
    expect(rules.falling(24, 18, 10), isTrue);
    expect(rules.falling(17.9, 21, 4), isFalse);
    expect(rules.falling(22, 24.1, 4), isFalse);
    expect(rules.falling(22, 21, 10.1), isFalse);
  });

  test('consulta orígenes de la cuenta sin enviar el JWT a Open-Meteo y agrupa productos', () async {
    final backend = fixtures.repository((request) async {
      expect(request.url.path, '/api/v1/dashboard/productos-relevantes');
      expect(request.headers['Authorization'], 'Bearer token-local-de-prueba');
      return fixtures.jsonResponse({
        'productos': [
          fixtures.product(fixtures.seller),
          {...fixtures.product(fixtures.seller), 'id': 'segundo'},
        ],
      });
    });
    var geocoding = 0, forecasts = 0;
    final weather = ClimateRepository(
      backend,
      client: MockClient((request) async {
        expect(request.headers.containsKey('Authorization'), isFalse);
        if (request.url.host == 'geocoding-api.open-meteo.com') {
          geocoding++;
          return fixtures.jsonResponse({
            'results': [
              {
                'name': 'Pasto / Airport',
                'country': 'Colombia',
                'latitude': 1.4,
                'longitude': -77.2,
              },
              {
                'name': 'Pasto',
                'country': 'Colombia',
                'latitude': 1.2,
                'longitude': -77.3,
              },
            ],
          });
        }
        expect(request.url.host, 'api.open-meteo.com');
        expect(request.url.queryParameters['forecast_days'], '1');
        forecasts++;
        return fixtures.jsonResponse({
          'current': {'temperature_2m': 22},
          'daily': {
            'temperature_2m_max': [24],
            'temperature_2m_min': [18],
            'rain_sum': [4],
          },
        });
      }),
    );
    addTearDown(backend.api.close);
    addTearDown(weather.close);
    final result = await weather.fetch();
    expect(result.readings.single.products.length, 2);
    expect(result.readings.single.falling, isTrue);
    await weather.fetch();
    expect(geocoding, 1);
    expect(forecasts, 2);
  });

  test('datos meteorológicos nulos no generan una tendencia falsa', () async {
    final backend = fixtures.repository(
      (_) async => fixtures.jsonResponse({
        'productos': [fixtures.product(fixtures.seller)],
      }),
    );
    final weather = ClimateRepository(
      backend,
      client: MockClient(
        (request) async => request.url.path == '/v1/search'
            ? fixtures.jsonResponse({
                'results': [
                  {
                    'name': 'Pasto',
                    'country': 'Colombia',
                    'latitude': 1.2,
                    'longitude': -77.3,
                  },
                ],
              })
            : fixtures.jsonResponse({
                'current': {'temperature_2m': null},
                'daily': {},
              }),
      ),
    );
    addTearDown(backend.api.close);
    addTearDown(weather.close);
    final result = await weather.fetch();
    expect(result.readings, isEmpty);
    expect(result.notices, isNotEmpty);
  });

  testWidgets(
    'consulta cada minuto, pausa en segundo plano y no solapa solicitudes',
    (tester) async {
      var calls = 0;
      Completer<ClimateSnapshot>? pending;
      var now = DateTime(2026, 11, 8);
      final controller = ClimateController(
        now: () => now,
        load: () {
          calls++;
          return pending?.future ?? Future.value(snapshot());
        },
      );
      controller.start();
      await tester.pump();
      expect(calls, 1);
      await tester.pump(const Duration(minutes: 1));
      expect(calls, 2);
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(const Duration(minutes: 2));
      expect(calls, 2);
      now = now.add(const Duration(minutes: 3));
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(calls, 3);
      pending = Completer<ClimateSnapshot>();
      unawaited(controller.refresh());
      await tester.pump();
      await tester.pump(const Duration(minutes: 1));
      expect(calls, 4);
      controller.dispose();
      pending.complete(snapshot());
      await tester.pump();
      await tester.pump(const Duration(minutes: 1));
      expect(calls, 4);
    },
  );

  testWidgets(
    'el aviso no se repite sin cambios y conserva datos cuando falla la red',
    (tester) async {
      var now = DateTime(2026, 11, 8);
      var falling = false, fails = false;
      final controller = ClimateController(
        now: () => now,
        load: () async {
          if (fails) throw StateError('sin conexión');
          return snapshot(falling: falling);
        },
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.unseen, hasLength(1));
      controller.acknowledge(controller.unseen);
      await controller.refresh();
      expect(controller.unseen, isEmpty);
      falling = true;
      await controller.refresh();
      expect(controller.unseen, isEmpty);
      now = now.add(const Duration(minutes: 16));
      expect(controller.unseen, hasLength(1));
      controller.acknowledge(controller.unseen);
      fails = true;
      await controller.refresh();
      expect(controller.data.readings.single.falling, isTrue);
      expect(controller.error, isNotNull);
      expect(controller.unseen, isEmpty);
    },
  );

  for (final isSeller in [true, false]) {
    testWidgets('rol $isSeller muestra un modal y no lo repite al navegar', (
      tester,
    ) async {
      final backend = fixtures.repository(
        (request) async => fixtures.jsonResponse(
          request.url.path == '/api/v1/perfil'
              ? fixtures.seller
              : fixtures.dashboard({
                  ...fixtures.seller,
                  'rol': isSeller ? 'VENDEDOR' : 'COMPRADOR',
                }),
        ),
        isSeller: isSeller,
      );
      final climate = ClimateController(load: () async => snapshot());
      addTearDown(backend.api.close);
      addTearDown(climate.dispose);
      await tester.pumpWidget(
        fixtures.host(
          SessionWorkspace(
            repository: backend,
            climate: climate,
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('climate-trend-dialog')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('climate-trend-dialog')),
          matching: find.text('Precios subiendo'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      await climate.refresh();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('climate-trend-dialog')), findsNothing);
      expect(find.byKey(const Key('nav-role-switch')), findsNothing);
      await tester.tap(find.byKey(const Key('nav-tab-clima')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Consulta automática cada 1 minuto'),
        findsOneWidget,
      );
    });
  }

  for (final size in [const Size(375, 812), const Size(812, 375)]) {
    testWidgets('modal adaptable con texto grande en $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        fixtures.host(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (dialogContext) => MediaQuery(
                      data: MediaQuery.of(dialogContext).copyWith(
                        textScaler: const TextScaler.linear(2),
                        disableAnimations: true,
                      ),
                      child: ClimateTrendDialog(
                        readings: [reading(), reading(falling: true)],
                      ),
                    ),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
          dark: true,
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('climate-trend-dialog')), findsNothing);
    });
  }

  test(
    'el contrato Spring envía usuario y rol y permite login por identificador',
    () async {
      final backend = fixtures.repository((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (request.url.path.endsWith('/register')) {
          expect(body['username'], 'ana.finca');
          expect(body['rol'], 'VENDEDOR');
        } else {
          expect(body['email'], 'ana.finca');
        }
        return fixtures.jsonResponse({
          'accessToken': 'token-local',
          'tokenType': 'Bearer',
          'usuario': {...fixtures.seller, 'username': 'ana.finca'},
        });
      });
      addTearDown(backend.api.close);
      final auth = HttpAuthRepository(backend.api);
      final account = await auth.register(
        name: 'Ana',
        username: 'ana.finca',
        email: 'ana@example.test',
        password: 'Clave2026!',
        role: 'VENDEDOR',
      );
      expect(account.username, 'ana.finca');
      expect(
        (await auth.signIn(
          identifier: 'ana.finca',
          password: 'Clave2026!',
        )).role,
        'VENDEDOR',
      );
    },
  );

  test('los estados definitivos de órdenes tienen etiquetas legibles', () {
    expect(statusLabel('CONFIRMADA'), 'Confirmada');
    expect(statusLabel('EN_PREPARACION'), 'En preparación');
    expect(statusLabel('EN_TRANSITO'), 'En tránsito');
    expect(statusLabel('ENTREGADA'), 'Entregada');
  });
}
