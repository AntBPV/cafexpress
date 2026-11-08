/// Configuración pública. No colocar contraseñas ni secretos en dart-define.
class ApiConfig {
  const ApiConfig({
    this.baseUrl = '',
    this.loginPath = '/api/auth/login',
    this.registerPath = '/api/auth/register',
    this.springAuth = false,
    this.timeout = const Duration(seconds: 15),
  });

  factory ApiConfig.fromEnvironment() {
    const springAuth = bool.fromEnvironment('SPRING_AUTH');
    const login = String.fromEnvironment('AUTH_LOGIN_PATH');
    const register = String.fromEnvironment('AUTH_REGISTER_PATH');
    return ApiConfig(
      baseUrl: const String.fromEnvironment('API_BASE_URL'),
      springAuth: springAuth,
      loginPath: login.isNotEmpty
          ? login
          : (springAuth ? '/api/v1/auth/login' : '/api/auth/login'),
      registerPath: register.isNotEmpty
          ? register
          : (springAuth ? '/api/v1/auth/register' : '/api/auth/register'),
    );
  }

  final String baseUrl;
  final String loginPath;
  final String registerPath;
  final bool springAuth;
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
