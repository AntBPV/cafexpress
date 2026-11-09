import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cafexpress_frontend/core/config/api_config.dart';
import 'package:cafexpress_frontend/core/network/api_client.dart';
import 'package:cafexpress_frontend/features/auth/domain/auth_session.dart';
import 'package:cafexpress_frontend/features/workspace/data/marketplace_repository.dart';
import 'package:cafexpress_frontend/features/workspace/presentation/product_form_page.dart';
import 'package:cafexpress_frontend/features/workspace/presentation/product_pages.dart';
import 'package:cafexpress_frontend/features/workspace/presentation/order_pages.dart';

import 'sprint2_workspace_test.dart' as fixtures;

import 'package:cafexpress_frontend/features/workspace/presentation/workspace_widgets.dart';

Map<String, dynamic> orderData([String state = 'SOLICITADA']) => {
  ...fixtures.order,
  'estado': state,
  'precioUnitario': 25000,
  'precioTotal': 50000,
  'comprador': {
    ...fixtures.seller,
    'id': 'comprador-1',
    'rol': 'COMPRADOR',
    'nombre': 'Comprador',
  },
  'vendedor': fixtures.seller,
  if (state != 'SOLICITADA') 'aceptadaEn': '2026-11-08T12:00:00Z',
};
MarketplaceRepository repository(
  Future<http.Response> Function(http.Request) handler, {
  bool seller = true,
}) => MarketplaceRepository(
  ApiClient(
    config: const ApiConfig(baseUrl: 'http://backend.test', springAuth: true),
    client: MockClient(handler),
  ),
  AuthSession(
    accessToken: 'token-de-prueba',
    role: seller ? 'VENDEDOR' : 'COMPRADOR',
    userId: seller ? 'vendedor-1' : 'comprador-1',
  ),
);

void main() {
  testWidgets(
    'actualizar una vista remota conserva un callback síncrono y muestra los datos nuevos',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        fixtures.host(
          Scaffold(
            body: RemoteView<int>(
              load: () async => ++calls,
              onSessionExpired: () {},
              builder: (value, reload) => Column(
                children: [
                  Text('Versión $value'),
                  TextButton(
                    onPressed: reload,
                    child: const Text('Actualizar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Versión 1'), findsOneWidget);
      await tester.tap(find.text('Actualizar'));
      await tester.pumpAndSettle();
      expect(find.text('Versión 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'filtros combinados conservan autorización y codifican país y origen',
    () async {
      final repo = repository((request) async {
        expect(request.headers['Authorization'], 'Bearer token-de-prueba');
        expect(request.url.queryParameters, {
          'page': '0',
          'size': '12',
          'tipo': 'CACAO',
          'paisOrigen': 'Colombia',
          'lugarOrigen': 'San Andrés',
          'precioMin': '100',
          'precioMax': '200',
        });
        return fixtures.jsonResponse({
          'content': [],
          'page': 0,
          'totalElements': 0,
          'totalPages': 0,
        });
      }, seller: false);
      addTearDown(repo.api.close);
      await repo.products(
        type: 'CACAO',
        country: ' Colombia ',
        origin: 'San Andrés',
        minimumPrice: 100,
        maximumPrice: 200,
      );
    },
  );

  testWidgets(
    'publicar valida cantidades y conserva el formulario tras error sin duplicar envíos',
    (tester) async {
      final pending = Completer<http.Response>();
      var calls = 0;
      final repo = repository((request) {
        calls++;
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/vendedor/productos');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['cantidadDisponible'], 2.5);
        expect(body['variedad'], 'Bourbon');
        expect(body['tipo'], 'CAFE');
        return pending.future;
      });
      addTearDown(repo.api.close);
      await tester.pumpWidget(
        fixtures.host(
          ProductFormPage(repository: repo, onSessionExpired: () {}),
        ),
      );
      for (final entry in {
        'name': 'Café integrado',
        'variety': 'Bourbon',
        'origin': 'Pasto',
        'stock': '-1',
        'price': '25000',
      }.entries) {
        await tester.enterText(
          find.byKey(Key('product-form-${entry.key}')),
          entry.value,
        );
      }
      final submit = find.byKey(const Key('product-form-save'));
      await fixtures.tapVisible(tester, submit);
      expect(calls, 0);
      await tester.enterText(
        find.byKey(const Key('product-form-stock')),
        '2,5',
      );
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pump();
      expect(calls, 1);
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      pending.complete(fixtures.jsonResponse({}, 500));
      await tester.pumpAndSettle();
      expect(find.text('Café integrado'), findsOneWidget);
      expect(find.text('Publicar producto'), findsWidgets);
    },
  );

  testWidgets(
    'filtros inválidos no consultan y los válidos llegan al backend',
    (tester) async {
      var calls = 0;
      Uri? last;
      final repo = repository((request) async {
        calls++;
        last = request.url;
        return fixtures.jsonResponse({
          'content': [],
          'page': 0,
          'totalElements': 0,
          'totalPages': 0,
        });
      }, seller: false);
      addTearDown(repo.api.close);
      await tester.pumpWidget(
        fixtures.host(
          ProductListPage(repository: repo, onSessionExpired: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 1);
      await tester.tap(find.text('Filtrar productos'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('filter-country')),
        'Colombia',
      );
      await tester.enterText(find.byKey(const Key('filter-minimum')), '200');
      await tester.enterText(find.byKey(const Key('filter-maximum')), '100');
      await fixtures.tapVisible(tester, find.byKey(const Key('filter-apply')));
      expect(calls, 1);
      await tester.enterText(find.byKey(const Key('filter-maximum')), '300');
      await fixtures.tapVisible(tester, find.byKey(const Key('filter-apply')));
      expect(calls, 2);
      expect(last!.queryParameters['paisOrigen'], 'Colombia');
      expect(last!.queryParameters['precioMax'], '300');
    },
  );

  testWidgets(
    'vendedor avanza una vez y ve el precio aplicado y el seguimiento',
    (tester) async {
      var state = 'SOLICITADA', calls = 0;
      final pending = Completer<http.Response>();
      final repo = repository((request) {
        if (request.method == 'PATCH') {
          calls++;
          expect(request.url.path, '/api/v1/vendedor/ordenes/orden-1/aceptar');
          return pending.future;
        }
        expect(request.url.path, '/api/v1/ordenes/orden-1');
        return Future.value(fixtures.jsonResponse(orderData(state)));
      });
      addTearDown(repo.api.close);
      await tester.pumpWidget(
        fixtures.host(
          OrderDetailPage(
            repository: repo,
            orderId: 'orden-1',
            onSessionExpired: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Total: 50.000'), findsOneWidget);
      final advance = find.byKey(const Key('order-advance'));
      await tester.ensureVisible(advance);
      await tester.pumpAndSettle();
      await tester.tap(advance);
      await tester.pump();
      expect(calls, 1);
      expect(tester.widget<FilledButton>(advance).onPressed, isNull);
      state = 'ACEPTADA';
      pending.complete(fixtures.jsonResponse(orderData(state)));
      await tester.pumpAndSettle();
      expect(find.text('Iniciar preparación'), findsOneWidget);
      expect(find.text('Aceptada'), findsOneWidget);
    },
  );

  testWidgets('comprador consulta detalle sin controles del vendedor', (
    tester,
  ) async {
    final repo = repository(
      (_) async => fixtures.jsonResponse(orderData()),
      seller: false,
    );
    addTearDown(repo.api.close);
    await tester.pumpWidget(
      fixtures.host(
        OrderDetailPage(
          repository: repo,
          orderId: 'orden-1',
          onSessionExpired: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-advance')), findsNothing);
    expect(find.byKey(const Key('order-reject')), findsNothing);
    expect(find.text('Precio aplicado por unidad: 25.000'), findsOneWidget);
  });

  testWidgets('historial usa su endpoint y mantiene la paginación', (
    tester,
  ) async {
    var history = false;
    final repo = repository((request) async {
      history = request.url.path.endsWith('/historial');
      return fixtures.jsonResponse({
        'content': history ? [orderData('ENTREGADA')] : [],
        'totalPages': 1,
        'totalElements': history ? 1 : 0,
      });
    });
    addTearDown(repo.api.close);
    await tester.pumpWidget(
      fixtures.host(OrdersReadPage(repository: repo, onSessionExpired: () {})),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(history, isTrue);
    expect(find.text('Estado: Entregada'), findsOneWidget);
  });

  testWidgets(
    'formulario de producto pinta errores de validación del backend en cada campo',
    (tester) async {
      final repo = repository((request) async {
        return fixtures.jsonResponse({
          'mensaje': 'Error de validación en los campos',
          'errores': {
            'nombre': 'El nombre ya existe en tu catálogo',
            'precioUnitario': 'El precio supera el límite permitido',
          },
        }, 422);
      });
      addTearDown(repo.api.close);
      await tester.pumpWidget(
        fixtures.host(
          ProductFormPage(repository: repo, onSessionExpired: () {}),
        ),
      );
      for (final entry in {
        'name': 'Café duplicado',
        'variety': 'Caturra',
        'origin': 'Huila',
        'stock': '10',
        'price': '35000',
      }.entries) {
        await tester.enterText(
          find.byKey(Key('product-form-${entry.key}')),
          entry.value,
        );
      }
      await fixtures.tapVisible(
        tester,
        find.byKey(const Key('product-form-save')),
      );
      expect(find.text('El nombre ya existe en tu catálogo'), findsOneWidget);
      expect(
        find.text('El precio supera el límite permitido'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'detalle de orden muestra indicador completo, refresca automáticamente y maneja cambios concurrentes',
    (tester) async {
      var currentState = 'SOLICITADA';
      final repo = repository((request) async {
        if (request.method == 'PATCH') {
          currentState = 'ACEPTADA';
          return fixtures.jsonResponse({
            'mensaje': 'La orden ya fue modificada desde otra sesión.',
          }, 409);
        }
        return fixtures.jsonResponse(orderData(currentState));
      });
      addTearDown(repo.api.close);
      await tester.pumpWidget(
        fixtures.host(
          OrderDetailPage(
            repository: repo,
            orderId: 'orden-1',
            onSessionExpired: () {},
            pollInterval: const Duration(seconds: 2),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('order-progress-indicator')),
        findsOneWidget,
      );
      expect(find.text('1. Solicitada'), findsOneWidget);
      expect(find.text('2. Confirmada'), findsOneWidget);
      expect(find.text('3. En preparación'), findsOneWidget);
      expect(find.text('4. En tránsito'), findsOneWidget);
      expect(find.text('5. Entregada'), findsOneWidget);

      final advance = find.byKey(const Key('order-advance'));
      await fixtures.tapVisible(tester, advance);
      expect(find.text('Iniciar preparación'), findsOneWidget);
      expect(
        find.textContaining('Acciones actualizadas'),
        findsOneWidget,
      );
    },
  );

  for (final size in [const Size(375, 812), const Size(812, 375)]) {
    testWidgets('formularios y órdenes adaptables en $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = repository((_) async => fixtures.jsonResponse(orderData()));
      addTearDown(repo.api.close);
      for (final child in <Widget>[
        ProductFormPage(repository: repo, onSessionExpired: () {}),
        OrderDetailPage(
          repository: repo,
          orderId: 'orden-1',
          onSessionExpired: () {},
        ),
      ]) {
        await tester.pumpWidget(
          fixtures.host(
            MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child,
            ),
            dark: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
