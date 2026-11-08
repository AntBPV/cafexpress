import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cafexpress_frontend/app.dart';
import 'package:cafexpress_frontend/core/config/api_config.dart';
import 'package:cafexpress_frontend/core/network/api_client.dart';
import 'package:cafexpress_frontend/features/auth/data/auth_repository.dart';
import 'package:cafexpress_frontend/features/workspace/data/marketplace_repository.dart';

void main() {
  const enabled = bool.fromEnvironment('LIVE_LOCAL_API');
  testWidgets(
    'flujo real: registro, perfil, publicación, compra, precio, entrega e historial',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final originalOverrides = HttpOverrides.current;
      addTearDown(() => HttpOverrides.global = originalOverrides);
      await tester.runAsync(() async {
        HttpOverrides.global = null;
        const fonts = String.fromEnvironment('PREVIEW_FONT_DIR');
        if (fonts.isNotEmpty) {
          for (final entry in {
            'Roboto': 'Roboto-Regular.ttf',
            'MaterialIcons': 'MaterialIcons-Regular.otf',
          }.entries) {
            final file = File('$fonts/${entry.value}');
            if (await file.exists()) {
              final loader = FontLoader(entry.key);
              loader.addFont(
                Future.value(ByteData.sublistView(await file.readAsBytes())),
              );
              await loader.load();
            }
          }
        }
      });
      final api = ApiClient(
        config: const ApiConfig(
          baseUrl: String.fromEnvironment(
            'LOCAL_API_URL',
            defaultValue: 'http://127.0.0.1:58081',
          ),
          springAuth: true,
          loginPath: '/api/v1/auth/login',
          registerPath: '/api/v1/auth/register',
        ),
      );
      addTearDown(api.close);
      final auth = HttpAuthRepository(api);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: CafeExpressApp(
            authRepository: auth,
            themeMode: ThemeMode.light,
          ),
        ),
      );
      final suffix = DateTime.now().millisecondsSinceEpoch.toString();
      final seller = 'vendedor.$suffix', buyer = 'comprador.$suffix';
      const password = 'Local2026!Cafe';
      final product = 'Café integrado $suffix';

      Future<void> ioTick() async {
        await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }

      Future<void> capture(String name) async {
        const directory = String.fromEnvironment('PREVIEW_OUTPUT_DIR');
        if (directory.isEmpty) return;
        await tester.pump();
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!.buffer.asUint8List();
          await File('$directory/$name.png').writeAsBytes(bytes);
          image.dispose();
        });
      }

      Future<void> waitFor(Finder finder) async {
        for (var i = 0; i < 120; i++) {
          await ioTick();
          if (finder.evaluate().isNotEmpty) return;
        }
        await capture('integracion-error');
        fail('No apareció: $finder');
      }

      Future<void> dismissClimate() async {
        if (find
            .byKey(const Key('climate-trend-dialog'))
            .evaluate()
            .isNotEmpty) {
          await capture('integracion-modal-clima');
          await tester.tap(find.text('Entendido'));
          await ioTick();
          await ioTick();
        }
      }

      Future<void> tap(Finder finder) async {
        await dismissClimate();
        await waitFor(finder);
        await tester.ensureVisible(finder);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(finder);
        await ioTick();
      }

      Future<void> enter(String key, String text) async {
        final finder = find.byKey(Key(key));
        await waitFor(finder);
        await tester.ensureVisible(finder);
        await tester.enterText(finder, text);
        await tester.pump();
      }

      Future<void> back() async {
        await dismissClimate();
        await tester.binding.handlePopRoute();
        await tester.pump(const Duration(milliseconds: 500));
        await ioTick();
      }

      Future<void> register(String username, String name, String role) async {
        await tap(find.byKey(const Key('login-register')));
        for (final entry in {
          'name': name,
          'username': username,
          'email': '$username@example.test',
          'password': password,
          'confirmation': password,
        }.entries) {
          await enter('register-${entry.key}', entry.value);
        }
        await tap(find.byKey(const Key('register-role')));
        await tap(find.text(role).last);
        await tap(find.byKey(const Key('register-submit')));
        await waitFor(find.byKey(const Key('login-registration-success')));
        expect(
          tester
              .widget<TextFormField>(find.byKey(const Key('login-identifier')))
              .controller!
              .text,
          username,
        );
      }

      Future<void> login(String identifier) async {
        await enter('login-identifier', identifier);
        await enter('login-password', password);
        await tap(find.byKey(const Key('login-submit')));
        await waitFor(find.byKey(const Key('login-open-navigation')));
        await tap(find.byKey(const Key('login-open-navigation')));
        await waitFor(find.byKey(const Key('nav-logout')));
        await dismissClimate();
      }

      Future<void> logout() async {
        await tap(find.byKey(const Key('nav-logout')));
        await waitFor(find.byKey(const Key('login-identifier')));
      }

      await register(seller, 'Vendedor integración', 'Vendedor');
      await login(seller);
      await tap(find.byKey(const Key('nav-tab-perfil')));
      await tap(find.byKey(const Key('profile-edit')));
      await enter('profile-company', 'Finca integración local');
      await enter('profile-country', 'Colombia');
      await tap(find.byKey(const Key('profile-save')));
      await waitFor(find.text('Finca integración local'));
      await tap(find.byKey(const Key('nav-tab-productos')));
      await tap(find.byKey(const Key('product-create')));
      for (final entry in {
        'name': product,
        'variety': 'Bourbon',
        'origin': 'Pasto',
        'stock': '10',
        'price': '25000',
      }.entries) {
        await enter('product-form-${entry.key}', entry.value);
      }
      await tap(find.byKey(const Key('product-form-save')));
      await waitFor(find.text(product));
      await capture('integracion-producto-publicado');
      await logout();

      await register(buyer, 'Comprador integración', 'Comprador');
      await login(buyer);
      await tap(find.byKey(const Key('nav-tab-catalogo')));
      await tap(find.text('Filtrar productos'));
      await enter('filter-country', 'Colombia');
      await enter('filter-minimum', '25000');
      await enter('filter-maximum', '25000');
      await tap(find.byKey(const Key('filter-apply')));
      await waitFor(find.text(product));
      await tap(find.text(product));
      await tap(find.byKey(const Key('product-start-order')));
      await enter('order-quantity', '2');
      await tap(find.byKey(const Key('order-submit')));
      await waitFor(find.text('Solicitud registrada'));
      expect(find.text('Total confirmado: 50.000'), findsOneWidget);
      await capture('integracion-solicitud-confirmada');
      await tap(find.text('Ver orden'));
      await waitFor(find.text('Total: 50.000'));
      expect(find.byKey(const Key('order-advance')), findsNothing);
      await back();
      await back();
      await logout();

      await login(seller);
      await tap(find.byKey(const Key('nav-tab-productos')));
      await tap(find.text(product));
      await tap(find.byKey(const Key('product-edit')));
      await enter('product-form-price', '30000');
      await tap(find.byKey(const Key('product-form-save')));
      await waitFor(find.text('30.000'));
      await back();
      await tap(find.byKey(const Key('nav-tab-ordenes')));
      await tap(find.text(product));
      await waitFor(find.text('Total: 50.000'));
      await tap(find.byKey(const Key('order-advance')));
      await waitFor(find.text('Iniciar preparación'));
      await tap(find.byKey(const Key('order-advance')));
      await waitFor(find.text('Marcar como enviada'));
      await tap(find.byKey(const Key('order-advance')));
      await waitFor(find.text('Confirmar entrega'));
      await capture('integracion-orden-enviada');
      await tap(find.byKey(const Key('order-advance')));
      await tap(find.text('Confirmar'));
      await waitFor(find.text('Estado: Entregada'));
      expect(find.byKey(const Key('order-advance')), findsNothing);
      await capture('integracion-orden-entregada');
      await back();
      await tap(find.text('Historial'));
      await waitFor(find.text(product));
      await tap(find.byKey(const Key('nav-tab-inicio')));
      await waitFor(find.text('Entregada: 1'));
      await capture('integracion-dashboard-vendedor');
      await logout();

      await login('$buyer@example.test');
      await tap(find.byKey(const Key('nav-tab-ordenes')));
      await tap(find.text('Historial'));
      await tap(find.text(product));
      await waitFor(find.text('Estado: Entregada'));
      expect(find.text('Total: 50.000'), findsOneWidget);
      await capture('integracion-detalle-comprador');
      await back();
      await tap(find.byKey(const Key('nav-tab-clima')));
      await waitFor(find.text('Actualizar clima'));
      if (find.byKey(const Key('climate-trend-dialog')).evaluate().isEmpty) {
        final refresh = find.widgetWithText(TextButton, 'Actualizar clima');
        if (tester.widget<TextButton>(refresh).onPressed != null) {
          await tap(refresh);
        }
      }
      await waitFor(find.textContaining('Última consulta:'));
      await dismissClimate();
      await capture('integracion-clima-comprador');

      await tester.runAsync(() async {
        final verificationApi = ApiClient(config: api.config);
        final session = await HttpAuthRepository(verificationApi)
            .signIn(identifier: seller, password: password);
        final repo = MarketplaceRepository(verificationApi, session);
        final products = await repo.products();
        final saved = products.items.singleWhere(
          (item) => item.name == product,
        );
        expect(saved.availableAmount, 8);
        expect(saved.price, 30000);
        expect(saved.variety, 'Bourbon');
        final history = await repo.orderPage(history: true);
        expect(history.items.single.total, 50000);
        expect(history.items.single.state, 'ENTREGADA');
        expect(history.items.single.events, hasLength(5));
        expect((await repo.dashboard()).activeOrders, 0);
        verificationApi.close();
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      api.close();
      await ioTick();
      await tester.pump();
    },
    skip: !enabled,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
