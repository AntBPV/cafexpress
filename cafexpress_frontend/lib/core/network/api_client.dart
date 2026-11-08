import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

/// Cliente JSON reutilizable. El cliente HTTP se inyecta para poder probarlo.
class ApiClient {
  ApiClient({required this.config, http.Client? client})
    : _client = client ?? http.Client();

  final ApiConfig config;
  final http.Client _client;

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? authorization,
    String unavailableMessage =
        'El servicio aún no está disponible. Inténtalo más tarde.',
    String invalidResponseMessage =
        'No pudimos completar la solicitud. Inténtalo de nuevo más tarde.',
    Map<int, String> errorMessages = const {},
  }) => _request(
    'POST',
    path,
    body: body,
    authorization: authorization,
    unavailableMessage: unavailableMessage,
    invalidResponseMessage: invalidResponseMessage,
    errorMessages: errorMessages,
  );

  Future<Map<String, dynamic>> getJson(
    String path, {
    required String authorization,
  }) => _request('GET', path, authorization: authorization);

  Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
    required String authorization,
  }) => _request('PUT', path, body: body, authorization: authorization);

  Future<Map<String, dynamic>> patchJson(
    String path, {
    required String authorization,
    Map<int, String> errorMessages = const {},
  }) => _request(
    'PATCH',
    path,
    authorization: authorization,
    errorMessages: errorMessages,
  );

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    required String authorization,
    Map<int, String> errorMessages = const {},
  }) => _request(
    'DELETE',
    path,
    authorization: authorization,
    errorMessages: errorMessages,
  );

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? authorization,
    String unavailableMessage = 'El servicio no está disponible.',
    String invalidResponseMessage = 'La respuesta del servidor no es válida.',
    Map<int, String> errorMessages = const {},
  }) async {
    if (!config.isConfigured) {
      throw ApiException(unavailableMessage);
    }

    try {
      final request = http.Request(method, config.endpoint(path))
        ..headers.addAll({
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Authorization': ?authorization,
        });
      if (body != null) request.body = jsonEncode(body);
      final response = await (() async {
        final streamed = await _client.send(request);
        return http.Response.fromStream(streamed);
      })().timeout(config.timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          errorMessages[response.statusCode] ??
              _messageForStatus(response.statusCode, unavailableMessage),
          statusCode: response.statusCode,
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Se esperaba un objeto JSON.');
      }
      return decoded;
    } on TimeoutException {
      throw const ApiException(
        'La conexión tardó demasiado. Vuelve a intentarlo.',
      );
    } on http.ClientException {
      throw const ApiException(
        'No pudimos conectar. Revisa tu conexión y vuelve a intentarlo.',
      );
    } on FormatException {
      throw ApiException(invalidResponseMessage);
    }
  }

  String _messageForStatus(int status, String unavailableMessage) =>
      switch (status) {
        400 || 422 => 'Revisa los datos e inténtalo de nuevo.',
        401 => 'No se pudo autorizar la solicitud.',
        403 => 'No tienes permiso para realizar esta acción.',
        404 => unavailableMessage,
        409 => 'Los datos enviados ya están en uso.',
        429 =>
          'Hubo demasiados intentos. Espera un momento y vuelve a intentar.',
        _ => 'El servicio no está disponible. Inténtalo de nuevo más tarde.',
      };

  void close() => _client.close();
}
