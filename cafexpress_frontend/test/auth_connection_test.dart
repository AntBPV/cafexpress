import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cafexpress_frontend/core/config/api_config.dart';
import 'package:cafexpress_frontend/core/network/api_client.dart';
import 'package:cafexpress_frontend/core/network/api_exception.dart';
import 'package:cafexpress_frontend/features/auth/data/auth_repository.dart';

void main() {
  test('conserva el prefijo de la API y usa el endpoint configurable', () {
    const config = ApiConfig(
      baseUrl: 'https://example.test/v1/',
      loginPath: '/auth/login',
    );
    expect(
      config.endpoint(config.loginPath).toString(),
      'https://example.test/v1/auth/login',
    );
    expect(
      () => config.endpoint('https://other.test/login'),
      throwsFormatException,
    );
  });

  for (final identifier in ['cristhian.orbes', 'cristhian@example.test']) {
    test('envía $identifier y conserva la contraseña exactamente', () async {
      final api = ApiClient(
        config: const ApiConfig(
          baseUrl: 'https://example.test/v1',
          loginPath: '/login',
        ),
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.toString(), 'https://example.test/v1/login');
          expect(request.headers['Content-Type'], contains('application/json'));
          expect(request.headers.containsKey('Authorization'), isFalse);
          expect(jsonDecode(request.body), {
            'identifier': identifier,
            'password': ' contraseña con espacios ',
          });
          return http.Response(
            jsonEncode({
              'accessToken': 'token-solo-de-prueba',
              'tokenType': 'Bearer',
              'user': {'name': 'Cristhian', 'email': 'cristhian@example.test'},
            }),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final session = await HttpAuthRepository(api).signIn(
        identifier: ' $identifier ',
        password: ' contraseña con espacios ',
      );
      expect(session.authorizationHeader, 'Bearer token-solo-de-prueba');
      expect(session.name, 'Cristhian');
    });
  }

  test(
    'sin URL no envía credenciales ni devuelve una sesión ficticia',
    () async {
      var calls = 0;
      final api = ApiClient(
        config: const ApiConfig(),
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
      );
      addTearDown(api.close);
      await expectLater(
        HttpAuthRepository(api)
            .signIn(identifier: 'cristhian', password: 'clave'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'mensaje',
            contains('aún no está disponible'),
          ),
        ),
      );
      expect(calls, 0);
    },
  );

  for (final status in [400, 401, 403, 404, 422, 429, 500]) {
    test('traduce HTTP $status sin exponer el cuerpo del servidor', () async {
      final api = ApiClient(
        config: const ApiConfig(baseUrl: 'https://example.test'),
        client: MockClient(
          (_) async =>
              http.Response('<html>dato privado del servidor</html>', status),
        ),
      );
      addTearDown(api.close);
      await expectLater(
        HttpAuthRepository(api)
            .signIn(identifier: 'cristhian', password: 'clave'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'código', status)
              .having(
                (e) => e.message,
                'mensaje seguro',
                isNot(contains('dato privado')),
              ),
        ),
      );
    });
  }

  for (final body in [
    '{}',
    '[]',
    '<html>Error</html>',
    '{"accessToken":""}',
    '{"accessToken":true}',
    '{"accessToken":"token","user":[]}',
  ]) {
    test('rechaza una respuesta exitosa inválida: $body', () async {
      final api = ApiClient(
        config: const ApiConfig(baseUrl: 'https://example.test'),
        client: MockClient((_) async => http.Response(body, 200)),
      );
      addTearDown(api.close);
      await expectLater(
        HttpAuthRepository(api)
            .signIn(identifier: 'cristhian', password: 'clave'),
        throwsA(isA<ApiException>()),
      );
    });
  }

  test('recupera un fallo de red como mensaje para el usuario', () async {
    final api = ApiClient(
      config: const ApiConfig(baseUrl: 'https://example.test'),
      client: MockClient(
        (_) async => throw http.ClientException('fallo interno'),
      ),
    );
    addTearDown(api.close);
    await expectLater(
      api.postJson('/login', body: {}),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'mensaje',
          contains('Revisa tu conexión'),
        ),
      ),
    );
  });

  test('limita el tiempo de espera de la conexión', () async {
    final api = ApiClient(
      config: const ApiConfig(
        baseUrl: 'https://example.test',
        timeout: Duration(milliseconds: 5),
      ),
      client: MockClient((_) => Completer<http.Response>().future),
    );
    addTearDown(api.close);
    await expectLater(
      api.postJson('/login', body: {}),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'mensaje',
          contains('tardó demasiado'),
        ),
      ),
    );
  });
}
