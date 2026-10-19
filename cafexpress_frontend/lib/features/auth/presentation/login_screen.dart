import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/registered_account.dart';
import 'register_screen.dart';
import 'widgets/auth_feedback.dart';
import 'widgets/auth_scaffold.dart';

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
  bool _isOpeningRegister = false;
  String? _errorMessage;
  String? _registrationMessage;
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
    if (_errorMessage != null || _registrationMessage != null) {
      setState(() {
        _errorMessage = null;
        _registrationMessage = null;
      });
    }
  }

  Future<void> _openRegistration() async {
    if (_isSubmitting || _isOpeningRegister) return;
    FocusManager.instance.primaryFocus?.unfocus();
    TextInput.finishAutofillContext(shouldSave: false);
    _password.clear();
    setState(() {
      _isOpeningRegister = true;
      _obscurePassword = true;
      _errorMessage = null;
      _registrationMessage = null;
    });
    final account = await Navigator.of(context).push<RegisteredAccount>(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(authRepository: widget.authRepository),
      ),
    );
    if (!mounted) return;
    if (account != null) _formKey.currentState?.reset();
    setState(() {
      _isOpeningRegister = false;
      if (account != null) {
        _identifier.text = account.username;
        _password.clear();
        _hasSubmitted = false;
        _registrationMessage = 'Cuenta creada. Inicia sesión para continuar.';
      }
    });
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
      _registrationMessage = null;
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
      _registrationMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AuthScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
              style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 40),
            if (_registrationMessage case final message?) ...[
              AuthFeedback(
                key: const Key('login-registration-success'),
                message: message,
                isError: false,
              ),
              const SizedBox(height: 24),
            ],
            _buildForm(context),
            const SizedBox(height: 16),
            TextButton(
              key: const Key('login-register'),
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: _isSubmitting || _isOpeningRegister
                  ? null
                  : _openRegistration,
              child: const Text(
                '¿No tienes cuenta? Regístrate',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
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
              AuthFeedback(key: const Key('login-error'), message: message),
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
