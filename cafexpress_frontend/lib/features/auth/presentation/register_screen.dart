import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import 'widgets/auth_feedback.dart';
import 'widgets/auth_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _nameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmationFocus = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _username,
      _email,
      _password,
      _confirmation,
    ]) {
      controller.dispose();
    }
    for (final focus in [
      _nameFocus,
      _usernameFocus,
      _emailFocus,
      _passwordFocus,
      _confirmationFocus,
    ]) {
      focus.dispose();
    }
    super.dispose();
  }

  String? _validateName(String? value) =>
      value == null || value.trim().isEmpty ? 'Escribe tu nombre.' : null;

  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) return 'Elige un nombre de usuario.';
    if (RegExp(r'[\s@]').hasMatch(username)) {
      return 'Usa un nombre de usuario sin espacios ni @.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Escribe tu correo electrónico.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Escribe un correo electrónico válido.';
    }
    return null;
  }

  String? _validatePassword(String? value) =>
      value == null || value.isEmpty ? 'Escribe una contraseña.' : null;

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña.';
    if (value != _password.text) return 'Las contraseñas no coinciden.';
    return null;
  }

  void _clearError(String _) {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  void _showError(String message) {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    setState(() {
      _isSubmitting = false;
      _errorMessage = message;
    });
  }

  Future<void> _register() async {
    if (_isSubmitting) return;
    setState(() => _hasSubmitted = true);
    if (!_formKey.currentState!.validate()) {
      setState(
        () =>
            _errorMessage = 'Revisa los campos marcados para crear tu cuenta.',
      );
      final fields = [
        (_name, _nameFocus, _validateName),
        (_username, _usernameFocus, _validateUsername),
        (_email, _emailFocus, _validateEmail),
        (_password, _passwordFocus, _validatePassword),
        (_confirmation, _confirmationFocus, _validateConfirmation),
      ];
      for (final (controller, focus, validate) in fields) {
        if (validate(controller.text) != null) {
          focus.requestFocus();
          break;
        }
      }
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final account = await widget.authRepository.register(
        name: _name.text.trim(),
        username: _username.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      TextInput.finishAutofillContext();
      _password.clear();
      _confirmation.clear();
      Navigator.of(context).pop(account);
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('No pudimos crear tu cuenta. Vuelve a intentarlo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthScaffold(
      showBackButton: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('Crea tu cuenta', style: theme.textTheme.headlineLarge),
          ),
          const SizedBox(height: 16),
          Text(
            'Completa tus datos para registrarte en Caféxpress.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 40),
          _buildForm(context),
          const SizedBox(height: 16),
          TextButton(
            key: const Key('register-login'),
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: _isSubmitting
                ? null
                : () => Navigator.of(context).maybePop(),
            child: const Text(
              '¿Ya tienes cuenta? Inicia sesión',
              textAlign: TextAlign.center,
            ),
          ),
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
              key: const Key('register-name'),
              controller: _name,
              focusNode: _nameFocus,
              readOnly: _isSubmitting,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Tu nombre',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: _validateName,
              onChanged: _clearError,
              onFieldSubmitted: (_) => _usernameFocus.requestFocus(),
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('register-username'),
              controller: _username,
              focusNode: _usernameFocus,
              readOnly: _isSubmitting,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newUsername],
              decoration: const InputDecoration(
                labelText: 'Usuario',
                hintText: 'Elige tu nombre de usuario',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: _validateUsername,
              onChanged: _clearError,
              onFieldSubmitted: (_) => _emailFocus.requestFocus(),
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('register-email'),
              controller: _email,
              focusNode: _emailFocus,
              readOnly: _isSubmitting,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                hintText: 'tu@correo.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: _validateEmail,
              onChanged: _clearError,
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 24),
            _buildPasswordField(confirmation: false),
            const SizedBox(height: 24),
            _buildPasswordField(confirmation: true),
            if (_errorMessage case final message?) ...[
              const SizedBox(height: 24),
              AuthFeedback(key: const Key('register-error'), message: message),
            ],
            const SizedBox(height: 32),
            FilledButton(
              key: const Key('register-submit'),
              onPressed: _isSubmitting ? null : _register,
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
                      _isSubmitting ? 'Creando cuenta…' : 'Crear cuenta',
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

  Widget _buildPasswordField({required bool confirmation}) {
    final obscure = confirmation ? _obscureConfirmation : _obscurePassword;
    return TextFormField(
      key: Key(confirmation ? 'register-confirmation' : 'register-password'),
      controller: confirmation ? _confirmation : _password,
      focusNode: confirmation ? _confirmationFocus : _passwordFocus,
      readOnly: _isSubmitting,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: confirmation
          ? TextInputAction.done
          : TextInputAction.next,
      autofillHints: const [AutofillHints.newPassword],
      decoration: InputDecoration(
        labelText: confirmation ? 'Confirmar contraseña' : 'Contraseña',
        hintText: confirmation ? 'Repite tu contraseña' : 'Crea una contraseña',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: confirmation
              ? (obscure ? 'Mostrar confirmación' : 'Ocultar confirmación')
              : (obscure ? 'Mostrar contraseña' : 'Ocultar contraseña'),
          onPressed: _isSubmitting
              ? null
              : () => setState(() {
                  if (confirmation) {
                    _obscureConfirmation = !_obscureConfirmation;
                  } else {
                    _obscurePassword = !_obscurePassword;
                  }
                }),
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: confirmation ? _validateConfirmation : _validatePassword,
      onChanged: _clearError,
      onFieldSubmitted: (_) =>
          confirmation ? _register() : _confirmationFocus.requestFocus(),
    );
  }
}
