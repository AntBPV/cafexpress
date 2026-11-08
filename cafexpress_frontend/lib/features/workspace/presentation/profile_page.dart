import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../data/marketplace_repository.dart';
import '../domain/marketplace_models.dart';
import 'workspace_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.repository,
    required this.onChanged,
    required this.onSessionExpired,
  });
  final MarketplaceRepository repository;
  final ValueChanged<Profile> onChanged;
  final VoidCallback onSessionExpired;
  @override
  Widget build(BuildContext context) => RemoteView<Profile>(
    load: repository.profile,
    onSessionExpired: onSessionExpired,
    builder: (profile, reload) => PageBody(
      onRefresh: reload,
      children: [
        PageHeading(
          title: 'Mi perfil',
          description: 'Los datos de tu cuenta en Caféxpress.',
          onRefresh: reload,
        ),
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: CircleAvatar(
                    radius: 28,
                    child: Text(
                      profile.name.characters.first.toUpperCase(),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  profile.roleLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                if (profile.username != null)
                  _ProfileValue('Usuario', profile.username),
                _ProfileValue('Correo electrónico', profile.email),
                if (profile.isSeller) ...[
                  _ProfileValue('Empresa o productor', profile.company),
                  _ProfileValue('País de origen', profile.country),
                  const SizedBox(height: 8),
                  if (!profile.isComplete)
                    const InfoNotice(
                      'Completa tu empresa o nombre de productor y tu país. Los compradores verán estos datos en tus productos.',
                    ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    key: const Key('profile-edit'),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(
                      profile.isComplete ? 'Editar perfil' : 'Completar perfil',
                    ),
                    onPressed: () async {
                      final saved = await Navigator.of(context).push<Profile>(
                        MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => EditSellerProfilePage(
                            repository: repository,
                            profile: profile,
                          ),
                        ),
                      );
                      if (saved != null) {
                        onChanged(saved);
                        await reload();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tu correo y tu rol identifican esta cuenta y no se modifican desde el perfil.',
        ),
      ],
    ),
  );
}

class _ProfileValue extends StatelessWidget {
  const _ProfileValue(this.label, this.value);
  final String label;
  final String? value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Semantics(
      container: true,
      label:
          '$label: ${value?.trim().isNotEmpty == true ? value! : "Sin completar"}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value?.trim().isNotEmpty == true ? value! : 'Sin completar',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    ),
  );
}

class EditSellerProfilePage extends StatefulWidget {
  const EditSellerProfilePage({
    super.key,
    required this.repository,
    required this.profile,
  });
  final MarketplaceRepository repository;
  final Profile profile;
  @override
  State<EditSellerProfilePage> createState() => _EditSellerProfilePageState();
}

class _EditSellerProfilePageState extends State<EditSellerProfilePage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.name);
  late final _company = TextEditingController(text: widget.profile.company);
  late final _country = TextEditingController(text: widget.profile.country);
  final _nameFocus = FocusNode(),
      _companyFocus = FocusNode(),
      _countryFocus = FocusNode();
  bool _saving = false, _submitted = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _country.dispose();
    _nameFocus.dispose();
    _companyFocus.dispose();
    _countryFocus.dispose();
    super.dispose();
  }

  String? _validate(String? value, int max) {
    if (value == null || value.trim().isEmpty) return 'Completa este campo.';
    if (value.trim().length > max) return 'Usa como máximo $max caracteres.';
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_form.currentState!.validate()) {
      for (final (controller, focus, max) in [
        (_name, _nameFocus, 100),
        (_company, _companyFocus, 120),
        (_country, _countryFocus, 80),
      ]) {
        if (_validate(controller.text, max) != null) {
          focus.requestFocus();
          break;
        }
      }
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final saved = await widget.repository.saveSellerProfile(
        name: _name.text,
        company: _company.text,
        country: _country.text,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context).pop(saved);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is ApiException
              ? error.message
              : 'No pudimos guardar el perfil. Inténtalo de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: PageBody(
          children: [
            const PageHeading(
              title: 'Tu identidad como vendedor',
              description:
                  'Esta información acompaña los productos que publicas.',
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Form(
                  key: _form,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        key: const Key('profile-name'),
                        controller: _name,
                        focusNode: _nameFocus,
                        readOnly: _saving,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => _validate(v, 100),
                        onFieldSubmitted: (_) => _companyFocus.requestFocus(),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: const Key('profile-company'),
                        controller: _company,
                        focusNode: _companyFocus,
                        readOnly: _saving,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Empresa o productor',
                          hintText: 'Ej. Cooperativa El Cafetal',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        validator: (v) => _validate(v, 120),
                        onFieldSubmitted: (_) => _countryFocus.requestFocus(),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        key: const Key('profile-country'),
                        controller: _country,
                        focusNode: _countryFocus,
                        readOnly: _saving,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'País de origen',
                          hintText: 'Ej. Colombia',
                          prefixIcon: Icon(Icons.public),
                        ),
                        validator: (v) => _validate(v, 80),
                        onFieldSubmitted: (_) => _save(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 24),
                        InfoNotice(_error!, isError: true),
                      ],
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        key: const Key('profile-save'),
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
