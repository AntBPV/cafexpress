import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/auth_session.dart';
import '../domain/registered_account.dart';

abstract interface class AuthRepository {
  Future<AuthSession> signIn({
    required String identifier,
    required String password,
  });

  Future<RegisteredAccount> register({
    required String name,
    required String username,
    required String email,
    required String password,
  });
}

class HttpAuthRepository implements AuthRepository {
  const HttpAuthRepository(this._api);

  final ApiClient _api;

  @override
  Future<AuthSession> signIn({
    required String identifier,
    required String password,
  }) async {
    final json = await _api.postJson(
      _api.config.loginPath,
      body: {'identifier': identifier.trim(), 'password': password},
      unavailableMessage:
          'El inicio de sesión aún no está disponible. Inténtalo más tarde.',
      invalidResponseMessage:
          'No pudimos completar el acceso. Inténtalo de nuevo más tarde.',
      errorMessages: const {
        401: 'El usuario, correo o contraseña no son correctos.',
        403: 'Tu cuenta no tiene acceso. Consulta con el administrador.',
      },
    );
    try {
      return AuthSession.fromJson(json);
    } on FormatException {
      throw const ApiException(
        'No pudimos completar el acceso. Inténtalo de nuevo más tarde.',
      );
    }
  }

  @override
  Future<RegisteredAccount> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final json = await _api.postJson(
      _api.config.registerPath,
      body: {
        'name': name.trim(),
        'username': username.trim(),
        'email': email.trim(),
        'password': password,
      },
      unavailableMessage:
          'El registro aún no está disponible. Inténtalo más tarde.',
      invalidResponseMessage:
          'No pudimos completar el registro. Inténtalo de nuevo más tarde.',
      errorMessages: const {
        401: 'No pudimos autorizar el registro. Inténtalo de nuevo más tarde.',
        403: 'El registro no está permitido en este momento.',
        409: 'El usuario o correo ya está registrado. Prueba con otros datos.',
      },
    );
    try {
      return RegisteredAccount.fromJson(json);
    } on FormatException {
      throw const ApiException(
        'No pudimos completar el registro. Inténtalo de nuevo más tarde.',
      );
    }
  }
}
