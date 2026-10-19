import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession> signIn({
    required String identifier,
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
    );
    try {
      return AuthSession.fromJson(json);
    } on FormatException {
      throw const ApiException(
        'No pudimos completar el acceso. Inténtalo de nuevo más tarde.',
      );
    }
  }
}
