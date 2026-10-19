/// Configuración pública. No colocar contraseñas ni secretos en dart-define.
class ApiConfig {
  const ApiConfig({
    this.baseUrl = '',
    this.loginPath = '/api/auth/login',
    this.timeout = const Duration(seconds: 15),
  });

  factory ApiConfig.fromEnvironment() => const ApiConfig(
    baseUrl: String.fromEnvironment('API_BASE_URL'),
    loginPath: String.fromEnvironment(
      'AUTH_LOGIN_PATH',
      defaultValue: '/api/auth/login',
    ),
  );

  final String baseUrl;
  final String loginPath;
  final Duration timeout;

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  /// Conserva prefijos como /v1 aunque el endpoint comience con una barra.
  Uri endpoint(String path) {
    final base = Uri.parse(baseUrl.trim());
    final relative = Uri.parse(path);
    if (!['http', 'https'].contains(base.scheme) ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        relative.hasScheme ||
        relative.hasAuthority ||
        relative.hasFragment) {
      throw const FormatException('Configuración de API no válida.');
    }
    final prefix = base.path.replaceAll(RegExp(r'/+$'), '');
    final suffix = relative.path.replaceAll(RegExp(r'^/+'), '');
    return base.replace(
      path: '$prefix/$suffix',
      query: relative.hasQuery ? relative.query : null,
    );
  }
}
