import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cafexpress_frontend/core/config/api_config.dart';
import 'package:cafexpress_frontend/core/network/api_client.dart';
import 'package:cafexpress_frontend/core/network/api_exception.dart';
import 'package:cafexpress_frontend/core/theme/app_theme.dart';
import 'package:cafexpress_frontend/features/auth/domain/auth_session.dart';
import 'package:cafexpress_frontend/features/workspace/data/marketplace_repository.dart';
import 'package:cafexpress_frontend/features/workspace/domain/marketplace_models.dart';
import 'package:cafexpress_frontend/features/workspace/presentation/session_workspace.dart';
import 'package:cafexpress_frontend/features/workspace/presentation/product_pages.dart';
import 'package:cafexpress_frontend/features/workspace/presentation/profile_page.dart';

Map<String, dynamic> seller = {
  'id': 'vendedor-1',
  'nombre': 'Ana Productora',
  'email': 'ana@example.test',
  'rol': 'VENDEDOR',
  'empresaProductor': 'Cooperativa Verde',
  'paisOrigen': 'Colombia',
};
Map<String, dynamic> product(Map<String, dynamic> profile) => {
  'id': 'producto-1',
  'nombre': 'Café de Pasto',
  'cantidadUnitaria': 1,
  'unidadCantidad': 'KILOGRAMOS',
  'cantidadDisponible': 8,
  'lugarOrigen': 'Pasto',
  'precioUnitario': 25000,
  'disponible': true,
  'vendedor': profile,
};
Map<String, dynamic> order = {
  'id': 'orden-1',
  'productoId': 'producto-1',
  'productoNombre': 'Café de Pasto',
  'cantidad': 2,
  'estado': 'SOLICITADA',
  'creadoEn': '2026-11-07T12:00:00Z',
};
Map<String, dynamic> dashboard(Map<String, dynamic> profile) => {
  'usuario': profile,
  'productosActivos': 1,
  'ordenesActivas': 1,
  'ordenesPorEstado': {'SOLICITADA': 1, 'ACEPTADA': 0, 'RECHAZADA': 0},
  'ordenesRecientes': [order],
  'actualizadoEn': '2026-11-07T12:00:00Z',
};

http.Response jsonResponse(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

MarketplaceRepository repository(
  Future<http.Response> Function(http.Request) handle, {
  bool isSeller = true,
}) => MarketplaceRepository(
  ApiClient(
    config: const ApiConfig(
      baseUrl: 'http://localhost:58080',
      springAuth: true,
    ),
    client: MockClient(handle),
  ),
  AuthSession(
    accessToken: 'token-local-de-prueba',
    role: isSeller ? 'VENDEDOR' : 'COMPRADOR',
    name: 'Ana Productora',
  ),
);

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Widget host(Widget child, {bool dark = false}) => MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
  home: child,
);

Profile constProfile() => Profile.fromJson(seller);
Product productModel() => Product.fromJson(product(seller));

void main() {
  test(
    'el conector envía autorización y solo los campos editables del perfil',
    () async {
      final repo = repository((request) async {
        expect(
          request.headers['Authorization'],
          'Bearer token-local-de-prueba',
        );
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/vendedor/perfil');
        expect(jsonDecode(request.body), {
          'nombre': 'Ana',
          'empresaProductor': 'Mi finca',
          'paisOrigen': 'Colombia',
        });
        return jsonResponse({
          ...seller,
          'nombre': 'Ana',
          'empresaProductor': 'Mi finca',
        });
      });
      addTearDown(repo.api.close);
      final saved = await repo.saveSellerProfile(
        name: ' Ana ',
        company: ' Mi finca ',
        country: ' Colombia ',
      );
      expect(saved.company, 'Mi finca');
    },
  );

  test(
    'consulta de producto registra el interés solo para el comprador',
    () async {
      for (final isSeller in [false, true]) {
        final methods = <String>[];
        final repo = repository((request) async {
          methods.add(request.method);
          expect(
            request.headers['Authorization'],
            'Bearer token-local-de-prueba',
          );
          if (request.method == 'POST') {
            expect(request.url.path, '/api/v1/productos/producto-1/consulta');
            return jsonResponse({'message': 'ok'});
          }
          return jsonResponse(product(seller));
        }, isSeller: isSeller);
        addTearDown(repo.api.close);
        expect(
          (await repo.product('producto-1')).seller.company,
          'Cooperativa Verde',
        );
        expect(methods, isSeller ? ['GET'] : ['GET', 'POST']);
      }
    },
  );

  test(
    'rechaza datos inválidos y conserva el código de sesión expirada',
    () async {
      final invalid = repository((_) async => jsonResponse({'usuario': {}}));
      addTearDown(invalid.api.close);
      await expectLater(invalid.dashboard(), throwsA(isA<ApiException>()));
      final expired = repository((_) async => jsonResponse({}, 401));
      addTearDown(expired.api.close);
      await expectLater(
        expired.profile(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    },
  );

  testWidgets(
    'dashboard muestra datos reales, oculta cambio de rol y abre el perfil',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final repo = repository((request) async {
        switch (request.url.path) {
          case '/api/v1/dashboard':
            return jsonResponse(dashboard(seller));
          case '/api/v1/dashboard/alertas':
            return jsonResponse({'alertas': [], 'avisos': []});
          case '/api/v1/perfil':
            return jsonResponse(seller);
          default:
            return jsonResponse({}, 404);
        }
      });
      addTearDown(repo.api.close);
      await tester.pumpWidget(
        host(SessionWorkspace(repository: repo, onSignOut: () {})),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hola, Ana Productora'), findsOneWidget);
      expect(find.text('Solicitada: 1'), findsOneWidget);
      expect(find.byKey(const Key('nav-role-switch')), findsNothing);
      await tester.tap(find.byKey(const Key('nav-tab-perfil')));
      await tester.pumpAndSettle();
      expect(find.text('Cooperativa Verde'), findsOneWidget);
      expect(find.text('Colombia'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Empresa o productor: Cooperativa Verde'),
        findsOneWidget,
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'perfil valida, retiene datos tras error y bloquea guardados duplicados',
    (tester) async {
      final pending = Completer<http.Response>();
      int calls = 0;
      final repo = repository((request) {
        calls++;
        return pending.future;
      });
      addTearDown(repo.api.close);
      await tester.pumpWidget(
        host(EditSellerProfilePage(repository: repo, profile: constProfile())),
      );
      await tester.pumpAndSettle();
      final company = find.byKey(const Key('profile-company'));
      final country = find.byKey(const Key('profile-country'));
      final save = find.byKey(const Key('profile-save'));
      await tester.enterText(company, ' ');
      await tapVisible(tester, save);
      expect(find.text('Completa este campo.'), findsOneWidget);
      expect(calls, 0);
      await tester.ensureVisible(company);
      await tester.enterText(company, 'Mi finca editada');
      await tester.ensureVisible(country);
      await tester.enterText(country, 'Ecuador');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pump();
      expect(calls, 1);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      pending.complete(jsonResponse({}, 500));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(company).controller!.text,
        'Mi finca editada',
      );
      expect(tester.widget<TextFormField>(country).controller!.text, 'Ecuador');
      expect(find.text('Guardar cambios'), findsOneWidget);
    },
  );

  testWidgets(
    'cantidad inválida no crea una orden y envía una sola solicitud válida',
    (tester) async {
      int requests = 0;
      final repo = repository((request) async {
        requests++;
        expect(request.url.path, '/api/v1/comprador/ordenes');
        expect(jsonDecode(request.body), {
          'productoId': 'producto-1',
          'cantidad': 2.5,
        });
        return jsonResponse({}, 409);
      }, isSeller: false);
      addTearDown(repo.api.close);
      await tester.pumpWidget(
        host(StartOrderPage(repository: repo, product: productModel())),
      );
      await tester.pumpAndSettle();
      final quantity = find.byKey(const Key('order-quantity'));
      final submit = find.byKey(const Key('order-submit'));
      await tester.enterText(quantity, '10');
      await tapVisible(tester, submit);
      expect(requests, 0);
      expect(
        find.text('La cantidad supera la disponibilidad.'),
        findsOneWidget,
      );
      await tester.ensureVisible(quantity);
      await tester.enterText(quantity, '2,5');
      await tapVisible(tester, submit);
      expect(requests, 1);
      expect(
        find.text('La cantidad disponible cambió. Actualiza el producto.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('sesión expirada permite volver al login', (tester) async {
    bool expired = false;
    final repo = repository((_) async => jsonResponse({}, 401));
    addTearDown(repo.api.close);
    await tester.pumpWidget(
      host(
        ProfilePage(
          repository: repo,
          onChanged: (_) {},
          onSessionExpired: () => expired = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tu sesión terminó'), findsOneWidget);
    await tester.tap(find.text('Volver al inicio de sesión'));
    expect(expired, isTrue);
  });

  for (final scenario in [
    (width: 375.0, height: 812.0, dark: false, scale: 1.0),
    (width: 812.0, height: 375.0, dark: false, scale: 1.0),
    (width: 1024.0, height: 768.0, dark: true, scale: 1.0),
    (width: 375.0, height: 812.0, dark: true, scale: 2.0),
  ]) {
    testWidgets('sprint 2 sin desbordamiento $scenario', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(scenario.width, scenario.height);
      tester.platformDispatcher.textScaleFactorTestValue = scenario.scale;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final repo = repository((request) async {
        if (request.url.path.endsWith('/alertas')) {
          return jsonResponse({'alertas': [], 'avisos': []});
        }
        if (request.url.path.endsWith('/perfil')) return jsonResponse(seller);
        return jsonResponse(dashboard(seller));
      });
      addTearDown(repo.api.close);
      await tester.pumpWidget(
        host(
          SessionWorkspace(repository: repo, onSignOut: () {}),
          dark: scenario.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('nav-tab-perfil')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.byKey(const Key('profile-edit')));
      expect(tester.takeException(), isNull);
    });
  }
}
