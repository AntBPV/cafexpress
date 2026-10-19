import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cafexpress_frontend/core/config/api_config.dart';
import 'package:cafexpress_frontend/core/network/api_client.dart';
import 'package:cafexpress_frontend/core/network/api_exception.dart';
import 'package:cafexpress_frontend/features/auth/data/auth_repository.dart';

void main() {
  test('registro configurable sin roles ni confirmación en el JSON', () async {
    final api = ApiClient(
      config: const ApiConfig(
        baseUrl: 'https://example.test/v1/',
        registerPath: '/cuentas',
      ),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://example.test/v1/cuentas');
        expect(request.headers['Content-Type'], contains('application/json'));
        expect(request.headers.containsKey('Authorization'), isFalse);
        expect(jsonDecode(request.body), {
          'name': 'Cristhian Orbes',
          'username': 'cristhian.orbes',
          'email': 'cristhian@example.test',
          'password': ' contraseña con espacios ',
        });
        return http.Response(
          jsonEncode({
            'user': {
              'name': 'Cristhian Orbes',
              'username': 'cristhian.orbes',
              'email': 'cristhian@example.test',
            },
          }),
          201,
        );
      }),
    );
    addTearDown(api.close);
    final account = await HttpAuthRepository(api).register(
      name: ' Cristhian Orbes ',
      username: ' cristhian.orbes ',
      email: ' cristhian@example.test ',
      password: ' contraseña con espacios ',
    );
    expect(account.username, 'cristhian.orbes');
    expect(account.email, 'cristhian@example.test');
    expect(account.name, 'Cristhian Orbes');
  });

  test('sin API no envía datos ni crea una cuenta ficticia', () async {
    var calls = 0;
    final api = ApiClient(
      config: const ApiConfig(),
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 201);
      }),
    );
    addTearDown(api.close);
    await expectLater(
      HttpAuthRepository(api).register(
        name: 'Cristhian',
        username: 'cristhian',
        email: 'cristhian@example.test',
        password: 'clave de prueba',
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'mensaje',
          'El registro aún no está disponible. Inténtalo más tarde.',
        ),
      ),
    );
    expect(calls, 0);
  });

  for (final status in [400, 401, 403, 404, 409, 422, 429, 500]) {
    test('registro traduce HTTP $status sin exponer el servidor', () async {
      final api = ApiClient(
        config: const ApiConfig(baseUrl: 'https://example.test'),
        client: MockClient(
          (_) async => http.Response('datos privados del servidor', status),
        ),
      );
      addTearDown(api.close);
      await expectLater(
        HttpAuthRepository(api).register(
          name: 'Cristhian',
          username: 'cristhian',
          email: 'cristhian@example.test',
          password: 'clave de prueba',
        ),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'HTTP', status)
              .having(
                (error) => error.message,
                'mensaje seguro',
                isNot(contains('datos privados')),
              )
              .having(
                (error) => error.message,
                'mensaje de registro',
                isNot(contains('inicio de sesión')),
              ),
        ),
      );
    });
  }

  for (final response in [
    '{}',
    '[]',
    '<html>Error</html>',
    '{"user":null}',
    '{"user":{"username":"","email":"cristhian@example.test"}}',
    '{"user":{"username":"cristhian","email":"correo"}}',
    '{"user":{"username":"con espacios","email":"cristhian@example.test"}}',
    '{"user":{"username":"cristhian","email":"cristhian@example.test","name":7}}',
  ]) {
    test('no confirma un registro con respuesta inválida: $response', () async {
      final api = ApiClient(
        config: const ApiConfig(baseUrl: 'https://example.test'),
        client: MockClient((_) async => http.Response(response, 201)),
      );
      addTearDown(api.close);
      await expectLater(
        HttpAuthRepository(api).register(
          name: 'Cristhian',
          username: 'cristhian',
          email: 'cristhian@example.test',
          password: 'clave de prueba',
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'mensaje',
            'No pudimos completar el registro. Inténtalo de nuevo más tarde.',
          ),
        ),
      );
    });
  }
}
