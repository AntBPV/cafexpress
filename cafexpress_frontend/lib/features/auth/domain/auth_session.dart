/// Contrato provisional: adaptar aquí el JSON cuando backend lo confirme.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    this.tokenType = 'Bearer',
    this.name,
    this.email,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken'];
    final tokenType = json['tokenType'] ?? 'Bearer';
    final user = json['user'];
    if (token is! String ||
        token.trim().isEmpty ||
        token.contains(RegExp(r'[\r\n]')) ||
        tokenType != 'Bearer' ||
        (user != null && user is! Map<String, dynamic>)) {
      throw const FormatException('Respuesta de autenticación no válida.');
    }
    final userData = user as Map<String, dynamic>?;
    final name = userData?['name'];
    final email = userData?['email'];
    if ((name != null && name is! String) ||
        (email != null && email is! String)) {
      throw const FormatException('Datos de usuario no válidos.');
    }
    return AuthSession(
      accessToken: token,
      tokenType: tokenType as String,
      name: name as String?,
      email: email as String?,
    );
  }

  final String accessToken;
  final String tokenType;
  final String? name;
  final String? email;

  String get authorizationHeader => '$tokenType $accessToken';
}
