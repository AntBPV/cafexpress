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
import 'package:cafexpress_frontend/features/auth/presentation/register_screen.dart';

class RegistrationRepository implements AuthRepository {
  RegistrationRepository(this.onRegister);
  final Future<RegisteredAccount> Function() onRegister;
  int registrationCalls = 0;
  int loginCalls = 0;

  @override
  Future<RegisteredAccount> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) {
    registrationCalls++;
    return onRegister();
  }

  @override
  Future<AuthSession> signIn({
    required String identifier,
    required String password,
  }) async {
    loginCalls++;
    return const AuthSession(accessToken: 'token-de-prueba');
  }
}

Finder field(String name) => find.byKey(Key('register-$name'));
Finder input(String name) =>
    find.descendant(of: field(name), matching: find.byType(TextField));
final submit = find.byKey(const Key('register-submit'));

Future<void> openRegistration(WidgetTester tester) async {
  final link = find.byKey(const Key('login-register'));
  await tester.ensureVisible(link);
  await tester.tap(link);
  await tester.pumpAndSettle();
}

Future<void> fillRegistration(
  WidgetTester tester, {
  String username = 'cristhian.orbes',
  String email = 'cristhian@example.test',
  String password = 'contraseña de prueba',
  String? confirmation,
}) async {
  final values = {
    'name': 'Cristhian Orbes',
    'username': username,
    'email': email,
    'password': password,
    'confirmation': confirmation ?? password,
  };
  for (final entry in values.entries) {
    await tester.ensureVisible(field(entry.key));
    await tester.enterText(field(entry.key), entry.value);
  }
}

Future<void> submitRegistration(WidgetTester tester) async {
  await tester.ensureVisible(submit);
  await tester.pumpAndSettle();
  await tester.tap(submit);
  await tester.pump();
}

void main() {
  testWidgets('login y registro permiten ir y volver sin duplicar pantallas', (
    tester,
  ) async {
    await tester.pumpWidget(const CafeExpressApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('login-identifier')),
      'usuario.existente',
    );
    await tester.enterText(find.byKey(const Key('login-password')), 'privada');
    await openRegistration(tester);
    expect(find.text('Crea tu cuenta'), findsOneWidget);
    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.textContaining('Vendedor'), findsNothing);
    expect(find.textContaining('Comprador'), findsNothing);
    final returnLink = find.byKey(const Key('register-login'));
    await tester.ensureVisible(returnLink);
    await tester.tap(returnLink);
    await tester.pumpAndSettle();
    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('login-identifier')))
          .controller!
          .text,
      'usuario.existente',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('login-password')))
          .controller!
          .text,
      isEmpty,
    );
    await openRegistration(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsNothing);
  });

  testWidgets('valida campos obligatorios y enfoca el primero incorrecto', (
    tester,
  ) async {
    final repo = RegistrationRepository(
      () async =>
          const RegisteredAccount(username: 'u', email: 'u@example.test'),
    );
    await tester.pumpWidget(CafeExpressApp(authRepository: repo));
    await tester.pumpAndSettle();
    await openRegistration(tester);
    await submitRegistration(tester);
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu nombre.'), findsOneWidget);
    expect(find.text('Elige un nombre de usuario.'), findsOneWidget);
    expect(find.text('Escribe tu correo electrónico.'), findsOneWidget);
    expect(find.text('Escribe una contraseña.'), findsOneWidget);
    expect(find.text('Confirma tu contraseña.'), findsOneWidget);
    expect(tester.widget<TextField>(input('name')).focusNode!.hasFocus, isTrue);
    expect(repo.registrationCalls, 0);
  });

  testWidgets(
    'rechaza usuario ambiguo, correo inválido y contraseñas distintas',
    (tester) async {
      final repo = RegistrationRepository(
        () async =>
            const RegisteredAccount(username: 'u', email: 'u@example.test'),
      );
      await tester.pumpWidget(CafeExpressApp(authRepository: repo));
      await tester.pumpAndSettle();
      await openRegistration(tester);
      await fillRegistration(
        tester,
        username: 'usuario@correo',
        email: 'correo@',
        confirmation: 'otra contraseña',
      );
      await submitRegistration(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('Usa un nombre de usuario sin espacios ni @.'),
        findsOneWidget,
      );
      expect(
        find.text('Escribe un correo electrónico válido.'),
        findsOneWidget,
      );
      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      expect(repo.registrationCalls, 0);
    },
  );

  testWidgets(
    'flujo con transporte inyectado vuelve al login y permite autenticarse',
    (tester) async {
      final requests = <String>[];
      final api = ApiClient(
        config: const ApiConfig(baseUrl: 'https://example.test'),
        client: MockClient((request) async {
          requests.add(request.url.path);
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (request.url.path == '/api/auth/register') {
            expect(body.keys.toSet(), {
              'name',
              'username',
              'email',
              'password',
            });
            return http.Response(
              '{"user":{"username":"cristhian.orbes","email":"cristhian@example.test"}}',
              201,
            );
          }
          expect(request.url.path, '/api/auth/login');
          expect(body['identifier'], 'cristhian.orbes');
          expect(body['password'], 'contraseña de prueba');
          return http.Response('{"accessToken":"token-de-prueba"}', 200);
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        CafeExpressApp(authRepository: HttpAuthRepository(api)),
      );
      await tester.pumpAndSettle();
      await openRegistration(tester);
      await fillRegistration(tester);
      await submitRegistration(tester);
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsNothing);
      expect(
        find.text('Cuenta creada. Inicia sesión para continuar.'),
        findsOneWidget,
      );
      expect(find.text('Sesión iniciada'), findsNothing);
      expect(requests, ['/api/auth/register']);
      final loginUser = find.byKey(const Key('login-identifier'));
      final loginPassword = find.byKey(const Key('login-password'));
      expect(
        tester.widget<TextFormField>(loginUser).controller!.text,
        'cristhian.orbes',
      );
      expect(
        tester.widget<TextFormField>(loginPassword).controller!.text,
        isEmpty,
      );
      await tester.ensureVisible(loginPassword);
      await tester.enterText(loginPassword, 'contraseña de prueba');
      final loginSubmit = find.byKey(const Key('login-submit'));
      await tester.ensureVisible(loginSubmit);
      await tester.tap(loginSubmit);
      await tester.pumpAndSettle();
      expect(find.text('Sesión iniciada'), findsOneWidget);
      expect(requests, ['/api/auth/register', '/api/auth/login']);
    },
  );

  testWidgets('sin backend mantiene el registro abierto y conserva los datos', (
    tester,
  ) async {
    await tester.pumpWidget(const CafeExpressApp());
    await tester.pumpAndSettle();
    await openRegistration(tester);
    await fillRegistration(tester);
    await submitRegistration(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('El registro aún no está disponible. Inténtalo más tarde.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(field('username')).controller!.text,
      'cristhian.orbes',
    );
    expect(
      tester.widget<TextFormField>(field('password')).controller!.text,
      'contraseña de prueba',
    );
    expect(
      find.text('Cuenta creada. Inicia sesión para continuar.'),
      findsNothing,
    );
  });

  testWidgets(
    'evita duplicados, conserva datos tras un error y permite reintentar',
    (tester) async {
      final pending = Completer<RegisteredAccount>();
      final repo = RegistrationRepository(() => pending.future);
      await tester.pumpWidget(CafeExpressApp(authRepository: repo));
      await tester.pumpAndSettle();
      await openRegistration(tester);
      await fillRegistration(tester);
      await submitRegistration(tester);
      expect(find.text('Creando cuenta…'), findsOneWidget);
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('register-login')))
            .onPressed,
        isNull,
      );
      tester.widget<TextField>(input('confirmation')).onSubmitted!('');
      await tester.pump();
      expect(repo.registrationCalls, 1);
      pending.completeError(
        const ApiException('El usuario o correo ya está registrado.'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('El usuario o correo ya está registrado.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextFormField>(field('email')).controller!.text,
        'cristhian@example.test',
      );
      expect(
        tester.widget<TextFormField>(field('confirmation')).controller!.text,
        'contraseña de prueba',
      );
      await tester.ensureVisible(field('username'));
      await tester.enterText(field('username'), 'otro.usuario');
      await submitRegistration(tester);
      await tester.pumpAndSettle();
      expect(repo.registrationCalls, 2);
      expect(repo.loginCalls, 0);
    },
  );

  testWidgets('regresar durante el envío ignora la respuesta tardía', (
    tester,
  ) async {
    final pending = Completer<RegisteredAccount>();
    await tester.pumpWidget(
      CafeExpressApp(
        authRepository: RegistrationRepository(() => pending.future),
      ),
    );
    await tester.pumpAndSettle();
    await openRegistration(tester);
    await fillRegistration(tester);
    await submitRegistration(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    pending.complete(
      const RegisteredAccount(
        username: 'cristhian',
        email: 'cristhian@example.test',
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(
      find.text('Cuenta creada. Inicia sesión para continuar.'),
      findsNothing,
    );
  });

  testWidgets('cada contraseña tiene su control de visibilidad accesible', (
    tester,
  ) async {
    await tester.pumpWidget(const CafeExpressApp());
    await tester.pumpAndSettle();
    await openRegistration(tester);
    for (final (key, tooltip) in [
      ('password', 'Mostrar contraseña'),
      ('confirmation', 'Mostrar confirmación'),
    ]) {
      final control = find.byTooltip(tooltip);
      await tester.ensureVisible(control);
      expect(
        tester
            .widget<TextField>(
              find.descendant(of: field(key), matching: find.byType(TextField)),
            )
            .obscureText,
        isTrue,
      );
      await tester.tap(control);
      await tester.pump();
      expect(
        tester
            .widget<TextField>(
              find.descendant(of: field(key), matching: find.byType(TextField)),
            )
            .obscureText,
        isFalse,
      );
    }
  });

  testWidgets(
    'registro conserva nombres accesibles y objetivos táctiles nativos',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(const CafeExpressApp());
      await tester.pumpAndSettle();
      await openRegistration(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    },
  );
}
