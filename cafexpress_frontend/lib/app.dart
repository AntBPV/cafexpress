import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/api_config.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_screen.dart';

class CafeExpressApp extends StatefulWidget {
  const CafeExpressApp({
    super.key,
    this.authRepository,
    this.themeMode = ThemeMode.system,
  });

  final AuthRepository? authRepository;
  final ThemeMode themeMode;

  @override
  State<CafeExpressApp> createState() => _CafeExpressAppState();
}

class _CafeExpressAppState extends State<CafeExpressApp> {
  ApiClient? _ownedApi;
  late final AuthRepository _authRepository;

  @override
  void initState() {
    super.initState();
    final injected = widget.authRepository;
    if (injected != null) {
      _authRepository = injected;
    } else {
      final api = ApiClient(config: ApiConfig.fromEnvironment());
      _ownedApi = api;
      _authRepository = HttpAuthRepository(api);
    }
  }

  @override
  void dispose() {
    _ownedApi?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Caféxpress',
    debugShowCheckedModeBanner: false,
    locale: const Locale('es'),
    supportedLocales: const [Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: widget.themeMode,
    home: LoginScreen(authRepository: _authRepository),
  );
}
