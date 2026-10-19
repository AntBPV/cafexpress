import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cafexpress_frontend/app.dart';

void main() {
  const reviewDir = String.fromEnvironment('VISUAL_REVIEW_DIR');
  const fontDir = String.fromEnvironment('REVIEW_FONT_DIR');
  setUpAll(() async {
    if (fontDir.isEmpty) return;
    final loader = FontLoader('Roboto');
    for (final weight in ['regular', 'medium', 'bold']) {
      loader.addFont(
        File('$fontDir/roboto-$weight.ttf')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)),
      );
    }
    await loader.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(
      File('$fontDir/materialicons-regular.otf')
          .readAsBytes()
          .then((bytes) => ByteData.sublistView(bytes)),
    );
    await icons.load();
  });

  final cases = [
    (
      name: 'movil',
      size: const Size(375, 812),
      dark: false,
      scale: 1.0,
      keyboard: false,
    ),
    (
      name: 'movil-oscuro',
      size: const Size(375, 812),
      dark: true,
      scale: 1.0,
      keyboard: false,
    ),
    (
      name: 'movil-horizontal',
      size: const Size(812, 375),
      dark: false,
      scale: 1.0,
      keyboard: false,
    ),
    (
      name: 'tablet',
      size: const Size(1024, 768),
      dark: false,
      scale: 1.0,
      keyboard: false,
    ),
    (
      name: 'tablet-oscuro',
      size: const Size(1024, 768),
      dark: true,
      scale: 1.0,
      keyboard: false,
    ),
    (
      name: 'texto-ampliado',
      size: const Size(375, 812),
      dark: false,
      scale: 2.0,
      keyboard: false,
    ),
    (
      name: 'teclado',
      size: const Size(375, 812),
      dark: false,
      scale: 1.0,
      keyboard: true,
    ),
    (
      name: 'pantalla-pequena',
      size: const Size(320, 568),
      dark: false,
      scale: 1.0,
      keyboard: false,
    ),
  ];

  for (final scenario in cases) {
    testWidgets('sin desbordamientos: ${scenario.name}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = scenario.size;
      tester.platformDispatcher.textScaleFactorTestValue = scenario.scale;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      if (scenario.keyboard) {
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      }
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: CafeExpressApp(
            themeMode: scenario.dark ? ThemeMode.dark : ThemeMode.light,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      if (reviewDir.isNotEmpty) {
        await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(reviewDir).create(recursive: true);
          await File('$reviewDir/${scenario.name}.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      final submit = find.byKey(const Key('login-submit'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        find.text('Escribe tu usuario o correo electrónico.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
