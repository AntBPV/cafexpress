import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../data/auth_repository.dart';
import '../domain/auth_session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authRepository});
  final AuthRepository authRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  String? _errorMessage;
  AuthSession? _session;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String? _validateIdentifier(String? value) {
    final identifier = value?.trim() ?? '';
    if (identifier.isEmpty) return 'Escribe tu usuario o correo electrónico.';
    if (identifier.contains('@') &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(identifier)) {
      return 'Escribe un correo electrónico válido.';
    }
    return null;
  }

  String? _validatePassword(String? value) =>
      value == null || value.isEmpty ? 'Escribe tu contraseña.' : null;

  void _clearError(String _) {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  Future<void> _signIn() async {
    if (_isSubmitting) return;
    setState(() => _hasSubmitted = true);
    if (!_formKey.currentState!.validate()) {
      setState(
        () => _errorMessage = 'Revisa los campos marcados para continuar.',
      );
      if (_validateIdentifier(_identifier.text) != null) {
        _identifierFocus.requestFocus();
      } else {
        _passwordFocus.requestFocus();
      }
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final session = await widget.authRepository.signIn(
        identifier: _identifier.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      TextInput.finishAutofillContext();
      _password.clear();
      setState(() => _session = session);
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _errorMessage = 'No pudimos iniciar sesión. Vuelve a intentarlo.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _signOut() {
    TextInput.finishAutofillContext(shouldSave: false);
    _identifier.clear();
    _password.clear();
    setState(() {
      _session = null;
      _hasSubmitted = false;
      _obscurePassword = true;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final expanded =
              constraints.maxWidth >= 900 && constraints.maxHeight >= 500;
          final content = _buildContent(context, expanded: expanded);
          if (!expanded) return content;
          return Row(
            children: [
              const Expanded(flex: 5, child: _BrandPanel()),
              Expanded(flex: 6, child: content),
            ],
          );
        },
      ),
    ),
  );

  Widget _buildContent(BuildContext context, {required bool expanded}) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.symmetric(
          horizontal: expanded ? 48 : 24,
          vertical: expanded ? 48 : 32,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - (expanded ? 96 : 64)).clamp(
              0,
              double.infinity,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!expanded) ...[
                    const _Wordmark(),
                    const SizedBox(height: 56),
                  ],
                  if (_session case final session?)
                    _buildSuccess(context, session)
                  else ...[
                    Semantics(
                      header: true,
                      child: Text('Inicia sesión', style: text.headlineLarge),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Accede a tu cuenta y continúa con tus compras y ventas.',
                      style: text.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildForm(context),
                  ],
                  const SizedBox(height: 48),
                  Divider(color: colors.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'De la preparación al destino, todo bajo control.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Form(
        key: _formKey,
        autovalidateMode: _hasSubmitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('login-identifier'),
              controller: _identifier,
              focusNode: _identifierFocus,
              readOnly: _isSubmitting,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(
                labelText: 'Usuario o correo',
                hintText: 'Usuario o correo',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: _validateIdentifier,
              onChanged: _clearError,
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('login-password'),
              controller: _password,
              focusNode: _passwordFocus,
              readOnly: _isSubmitting,
              obscureText: _obscurePassword,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Contraseña',
                hintText: 'Tu contraseña',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: _validatePassword,
              onChanged: _clearError,
              onFieldSubmitted: (_) => _signIn(),
            ),
            if (_errorMessage case final message?) ...[
              const SizedBox(height: 24),
              Semantics(
                liveRegion: true,
                child: Container(
                  key: const Key('login-error'),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: colors.onErrorContainer,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              key: const Key('login-submit'),
              onPressed: _isSubmitting ? null : _signIn,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSubmitting) ...[
                    SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      _isSubmitting ? 'Ingresando…' : 'Iniciar sesión',
                    ),
                  ),
                  if (!_isSubmitting) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess(BuildContext context, AuthSession session) {
    final theme = Theme.of(context);
    final name = session.name?.trim();
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text('Sesión iniciada', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 16),
          Text(
            name != null && name.isNotEmpty
                ? 'Bienvenido, $name. Has accedido a tu cuenta.'
                : 'Has accedido a tu cuenta correctamente.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          FilledButton(onPressed: _signOut, child: const Text('Cerrar sesión')),
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.eco_outlined,
            size: 36,
            color: onDark ? AppColors.gold : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            'Caféxpress',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: onDark ? AppColors.cream : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.coffee,
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Wordmark(onDark: true),
                  const SizedBox(height: 64),
                  const Spacer(),
                  Text(
                    'Café y cacao,',
                    style: Theme.of(context).textTheme.headlineLarge
                        ?.copyWith(color: AppColors.gold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'conectados con nuevos mercados.',
                    style: Theme.of(context).textTheme.headlineLarge
                        ?.copyWith(color: AppColors.cream),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Compra y vende tu producto desde un solo lugar.',
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: AppColors.cream),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
