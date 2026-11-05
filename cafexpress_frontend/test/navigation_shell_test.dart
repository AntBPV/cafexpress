import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cafexpress_frontend/app.dart';
import 'package:cafexpress_frontend/core/theme/app_theme.dart';
import 'package:cafexpress_frontend/features/navigation/domain/user_role.dart';
import 'package:cafexpress_frontend/features/navigation/presentation/main_navigation_shell.dart';

Widget buildTestShell({
  String? userName = 'Diego Cerón',
  UserRole initialRole = UserRole.comprador,
  int initialIndex = 0,
  VoidCallback? onSignOut,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    home: MainNavigationShell(
      userName: userName,
      initialRole: initialRole,
      initialIndex: initialIndex,
      onSignOut: onSignOut,
    ),
  );
}

void main() {
  testWidgets(
    'muestra NavigationBar para Comprador y permite recorrer las 5 pestañas',
    (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestShell());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('main-bottom-navigation')), findsOneWidget);
      expect(find.text('Resumen del Comprador'), findsOneWidget);

      await tester.tap(find.byKey(const Key('nav-tab-catalogo')));
      await tester.pumpAndSettle();
      expect(find.text('Catálogo de Café y Cacao'), findsOneWidget);

      await tester.tap(find.byKey(const Key('nav-tab-ordenes')));
      await tester.pumpAndSettle();
      expect(find.text('Mis Órdenes y Seguimiento'), findsOneWidget);

      await tester.tap(find.byKey(const Key('nav-tab-clima')));
      await tester.pumpAndSettle();
      expect(find.text('Alertas Climáticas de Compra'), findsOneWidget);

      await tester.tap(find.byKey(const Key('nav-tab-perfil')));
      await tester.pumpAndSettle();
      expect(find.text('Mi Perfil Individual'), findsOneWidget);
    },
  );

  testWidgets(
    'adapta las secciones de navegación al cambiar entre Comprador y Vendedor',
    (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      var signedOut = false;
      await tester.pumpWidget(
        buildTestShell(onSignOut: () => signedOut = true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rol: Comprador'), findsOneWidget);

      await tester.tap(find.byKey(const Key('nav-role-switch')));
      await tester.pumpAndSettle();

      expect(find.text('Rol: Vendedor'), findsOneWidget);
      expect(find.text('Resumen del Vendedor'), findsOneWidget);

      await tester.tap(find.byKey(const Key('nav-tab-productos')));
      await tester.pumpAndSettle();
      expect(find.text('Publicación y Gestión de Productos'), findsOneWidget);

      await tester.tap(find.byKey(const Key('nav-logout')));
      await tester.pumpAndSettle();
      expect(signedOut, isTrue);
    },
  );

  testWidgets(
    'usa NavigationRail en pantallas anchas y permite abrir desde LoginScreen',
    (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1024, 768);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const CafeExpressApp());
      await tester.pumpAndSettle();

      final previewButton = find.byKey(const Key('login-preview-navigation'));
      await tester.ensureVisible(previewButton);
      await tester.tap(previewButton);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('main-navigation-rail')), findsOneWidget);
      expect(find.text('Resumen del Comprador'), findsOneWidget);
    },
  );
}
