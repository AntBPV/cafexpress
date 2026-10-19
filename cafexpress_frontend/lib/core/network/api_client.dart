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
  }) async {
    if (!config.isConfigured) {
      throw const ApiException(
        'El inicio de sesión aún no está disponible. Inténtalo más tarde.',
      );
    }

    try {
      final response = await _client
          .post(
            config.endpoint(path),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Accept': 'application/json',
              'Authorization': ?authorization,
            },
            body: jsonEncode(body),
          )
          .timeout(config.timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _messageForStatus(response.statusCode),
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
      throw const ApiException(
        'No pudimos completar el acceso. Inténtalo de nuevo más tarde.',
      );
    }
  }

  String _messageForStatus(int status) => switch (status) {
    400 || 422 => 'Revisa los datos e inténtalo de nuevo.',
    401 => 'El usuario, correo o contraseña no son correctos.',
    403 => 'Tu cuenta no tiene acceso. Consulta con el administrador.',
    404 => 'El inicio de sesión aún no está disponible. Inténtalo más tarde.',
    429 => 'Hubo demasiados intentos. Espera un momento y vuelve a intentar.',
    _ => 'El servicio no está disponible. Inténtalo de nuevo más tarde.',
  };

  void close() => _client.close();
}
