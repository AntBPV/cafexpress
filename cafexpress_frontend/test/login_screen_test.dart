import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cafexpress_frontend/app.dart';
import 'package:cafexpress_frontend/core/config/api_config.dart';
import 'package:cafexpress_frontend/core/network/api_client.dart';
import 'package:cafexpress_frontend/core/network/api_exception.dart';
import 'package:cafexpress_frontend/features/auth/data/auth_repository.dart';
import 'package:cafexpress_frontend/features/auth/domain/auth_session.dart';
import 'package:cafexpress_frontend/features/auth/domain/registered_account.dart';

class ControlledAuthRepository implements AuthRepository {
  ControlledAuthRepository(this.response);
  final Future<AuthSession> Function() response;
  int calls = 0;

  @override
  Future<RegisteredAccount> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async => throw UnimplementedError('Este doble solo prueba el login.');

  @override
  Future<AuthSession> signIn({
    required String identifier,
    required String password,
  }) {
    calls++;
    return response();
  }
}

final identifierField = find.byKey(const Key('login-identifier'));
final passwordField = find.byKey(const Key('login-password'));
final submitButton = find.byKey(const Key('login-submit'));

Future<void> fillAndSubmit(
  WidgetTester tester, {
  String identifier = 'cristhian.orbes',
}) async {
  await tester.enterText(identifierField, identifier);
  await tester.enterText(passwordField, 'contraseña de prueba');
  await tester.ensureVisible(submitButton);
  await tester.tap(submitButton);
  await tester.pump();
}

void main() {
  testWidgets('los campos vacíos e inválidos no llegan al backend', (
    tester,
  ) async {
    final repo = ControlledAuthRepository(
      () async => const AuthSession(accessToken: 'prueba'),
    );
    await tester.pumpWidget(CafeExpressApp(authRepository: repo));
    await tester.pumpAndSettle();
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(
      find.text('Escribe tu usuario o correo electrónico.'),
      findsOneWidget,
    );
    expect(find.text('Escribe tu contraseña.'), findsOneWidget);
    expect(repo.calls, 0);
    await fillAndSubmit(tester, identifier: 'correo@');
    await tester.pumpAndSettle();
    expect(find.text('Escribe un correo electrónico válido.'), findsOneWidget);
    expect(repo.calls, 0);
  });

  for (final identifier in ['cristhian.orbes', 'cristhian@example.test']) {
    testWidgets('formulario y conector aceptan $identifier', (tester) async {
      final api = ApiClient(
        config: const ApiConfig(baseUrl: 'https://example.test'),
        client: MockClient((request) async {
          expect(request.url.path, '/api/auth/login');
          expect(jsonDecode(request.body)['identifier'], identifier);
          return http.Response(
            '{"accessToken":"prueba","user":{"name":"Cristhian"}}',
            200,
          );
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        CafeExpressApp(authRepository: HttpAuthRepository(api)),
      );
      await tester.pumpAndSettle();
      await fillAndSubmit(tester, identifier: identifier);
      await tester.pumpAndSettle();
      expect(find.text('Sesión iniciada'), findsOneWidget);
      expect(passwordField, findsNothing);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(identifierField).controller!.text,
        isEmpty,
      );
      expect(
        tester.widget<TextFormField>(passwordField).controller!.text,
        isEmpty,
      );
    });
  }

  testWidgets('muestra y oculta la contraseña sin enviar el formulario', (
    tester,
  ) async {
    final repo = ControlledAuthRepository(
      () async => const AuthSession(accessToken: 'prueba'),
    );
    await tester.pumpWidget(CafeExpressApp(authRepository: repo));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: passwordField,
              matching: find.byType(TextField),
            ),
          )
          .obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: passwordField,
              matching: find.byType(TextField),
            ),
          )
          .obscureText,
      isFalse,
    );
    await tester.tap(find.byTooltip('Ocultar contraseña'));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: passwordField,
              matching: find.byType(TextField),
            ),
          )
          .obscureText,
      isTrue,
    );
    expect(repo.calls, 0);
  });

  testWidgets(
    'bloquea solicitudes duplicadas y permite reintentar tras un fallo',
    (tester) async {
      final pending = Completer<AuthSession>();
      final repo = ControlledAuthRepository(() => pending.future);
      await tester.pumpWidget(CafeExpressApp(authRepository: repo));
      await tester.pumpAndSettle();
      await fillAndSubmit(tester);
      expect(find.text('Ingresando…'), findsOneWidget);
      expect(tester.widget<FilledButton>(submitButton).onPressed, isNull);
      tester
          .widget<TextField>(
            find.descendant(
              of: passwordField,
              matching: find.byType(TextField),
            ),
          )
          .onSubmitted!('');
      await tester.pump();
      expect(repo.calls, 1);
      pending.completeError(
        const ApiException('El usuario, correo o contraseña no son correctos.'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('El usuario, correo o contraseña no son correctos.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextFormField>(identifierField).controller!.text,
        'cristhian.orbes',
      );
      expect(
        tester.widget<TextFormField>(passwordField).controller!.text,
        'contraseña de prueba',
      );
      expect(tester.widget<FilledButton>(submitButton).onPressed, isNotNull);
    },
  );

  testWidgets(
    'sin API configurada explica la indisponibilidad y no autentica',
    (tester) async {
      await tester.pumpWidget(const CafeExpressApp());
      await tester.pumpAndSettle();
      await fillAndSubmit(tester);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'El inicio de sesión aún no está disponible. Inténtalo más tarde.',
        ),
        findsOneWidget,
      );
      expect(find.text('Sesión iniciada'), findsNothing);
    },
  );

  testWidgets('ignora la respuesta si se abandona la pantalla', (tester) async {
    final pending = Completer<AuthSession>();
    await tester.pumpWidget(
      CafeExpressApp(
        authRepository: ControlledAuthRepository(() => pending.future),
      ),
    );
    await tester.pumpAndSettle();
    await fillAndSubmit(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(const AuthSession(accessToken: 'prueba'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('controles accesibles con nombres y tamaño táctil', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const CafeExpressApp());
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
