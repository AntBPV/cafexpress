/// Contrato provisional del registro. Crear una cuenta no inicia una sesión.
class RegisteredAccount {
  const RegisteredAccount({
    required this.username,
    required this.email,
    this.name,
  });

  factory RegisteredAccount.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Respuesta de registro no válida.');
    }
    final username = user['username'];
    final email = user['email'];
    final name = user['name'];
    if (username is! String ||
        username.trim().isEmpty ||
        RegExp(r'[\s@]').hasMatch(username.trim()) ||
        email is! String ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim()) ||
        (name != null && name is! String)) {
      throw const FormatException('Datos de la cuenta no válidos.');
    }
    return RegisteredAccount(
      username: username.trim(),
      email: email.trim(),
      name: name as String?,
    );
  }

  final String username;
  final String email;
  final String? name;
}
