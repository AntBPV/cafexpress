import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../data/marketplace_repository.dart';
import '../domain/marketplace_models.dart';
import 'workspace_widgets.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({
    super.key,
    required this.repository,
    required this.onSessionExpired,
    this.product,
  });
  final MarketplaceRepository repository;
  final VoidCallback onSessionExpired;
  final Product? product;
  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _variety = TextEditingController(text: widget.product?.variety);
  late final _origin = TextEditingController(text: widget.product?.origin);
  late final _unitAmount = TextEditingController(
    text: widget.product?.unitAmount.toString() ?? '1',
  );
  late final _stock = TextEditingController(
    text: widget.product?.availableAmount.toString(),
  );
  late final _price = TextEditingController(
    text: widget.product?.price.toString(),
  );
  late String _type = widget.product?.type ?? 'CAFE',
      _unit = widget.product?.unit ?? 'KILOGRAMOS';
  late bool _available = widget.product?.available ?? true;
  bool _sending = false, _submitted = false;
  String? _error;
  @override
  void dispose() {
    for (final value in [
      _name,
      _variety,
      _origin,
      _unitAmount,
      _stock,
      _price,
    ]) {
      value.dispose();
    }
    super.dispose();
  }

  String? _text(String? value, int maximum, {bool required = true}) {
    if (required && (value?.trim().isEmpty ?? true)) {
      return 'Completa este campo.';
    }
    if ((value?.trim().length ?? 0) > maximum) {
      return 'Usa como máximo $maximum caracteres.';
    }
    return null;
  }

  num _number(TextEditingController controller) =>
      num.parse(controller.text.trim().replaceAll(',', '.'));
  String? _numeric(
    String? value,
    int integers,
    int decimals, {
    bool zero = false,
  }) {
    final text = value?.trim().replaceAll(',', '.') ?? '';
    final pattern = RegExp('^\\d{1,$integers}(\\.\\d{1,$decimals})?\$');
    final parsed = num.tryParse(text);
    if (!pattern.hasMatch(text) ||
        parsed == null ||
        !parsed.isFinite ||
        (zero ? parsed < 0 : parsed <= 0)) {
      return 'Ingresa un valor ${zero ? "igual o mayor que cero" : "mayor que cero"}, con hasta $decimals decimales.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_sending) return;
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      final product = await widget.repository.saveProduct({
        'nombre': _name.text.trim(),
        'tipo': _type,
        'variedad': _variety.text.trim(),
        'cantidadUnitaria': _number(_unitAmount),
        'unidadCantidad': _unit,
        'cantidadDisponible': _number(_stock),
        'lugarOrigen': _origin.text.trim(),
        'precioUnitario': _number(_price),
        'disponible': _available,
      }, id: widget.product?.id);
      if (!mounted) return;
      setState(() => _sending = false);
      Navigator.pop(context, product);
    } catch (failure) {
      if (!mounted) return;
      if (failure is ApiException && failure.statusCode == 401) {
        widget.onSessionExpired();
        return;
      }
      setState(() {
        _sending = false;
        _error = failure is ApiException
            ? failure.message
            : 'No pudimos guardar el producto. Reintenta.';
      });
    }
  }

  Widget _field(
    String key,
    String label,
    TextEditingController controller,
    String? Function(String?) validator, {
    bool numeric = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: TextFormField(
      key: Key('product-form-$key'),
      controller: controller,
      readOnly: _sending,
      decoration: InputDecoration(labelText: label),
      validator: validator,
      textInputAction: TextInputAction.next,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_sending,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Publicar producto' : 'Editar producto',
        ),
      ),
      body: SafeArea(
        child: PageBody(
          children: [
            PageHeading(
              title: widget.product == null
                  ? 'Publica tu producto'
                  : 'Actualiza tu producto',
              description: 'El precio se aplica a cada presentación. Los cambios se guardan para los compradores.',
            ),
            Form(
              key: _form,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field(
                    'name',
                    'Nombre del producto',
                    _name,
                    (v) => _text(v, 150),
                  ),
                  DropdownButtonFormField<String>(
                    key: const Key('product-form-type'),
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de producto',
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'CAFE', child: Text('Café')),
                      DropdownMenuItem(value: 'CACAO', child: Text('Cacao')),
                      DropdownMenuItem(
                        value: 'VARIEDAD',
                        child: Text('Variedad'),
                      ),
                    ],
                    onChanged: _sending ? null : (v) => _type = v!,
                  ),
                  const SizedBox(height: 20),
                  _field(
                    'variety',
                    'Variedad (opcional)',
                    _variety,
                    (v) => _text(v, 100, required: false),
                  ),
                  _field(
                    'origin',
                    'Origen: ciudad o región',
                    _origin,
                    (v) => _text(v, 100),
                  ),
                  _field(
                    'unit-amount',
                    'Cantidad por presentación',
                    _unitAmount,
                    (v) => _numeric(v, 7, 3),
                    numeric: true,
                  ),
                  DropdownButtonFormField<String>(
                    key: const Key('product-form-unit'),
                    initialValue: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Unidad de la presentación',
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'KILOGRAMOS',
                        child: Text('Kilogramos'),
                      ),
                      DropdownMenuItem(value: 'GRAMOS', child: Text('Gramos')),
                    ],
                    onChanged: _sending ? null : (v) => _unit = v!,
                  ),
                  const SizedBox(height: 20),
                  _field(
                    'stock',
                    'Presentaciones disponibles',
                    _stock,
                    (v) => _numeric(v, 9, 3, zero: true),
                    numeric: true,
                  ),
                  _field(
                    'price',
                    'Precio por presentación',
                    _price,
                    (v) => _numeric(v, 12, 2),
                    numeric: true,
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Disponible en el catálogo'),
                    value: _available,
                    onChanged: _sending
                        ? null
                        : (v) => setState(() => _available = v),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: InfoNotice(_error!, isError: true),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('product-form-save'),
                    onPressed: _sending ? null : _save,
                    child: Text(
                      _sending
                          ? 'Guardando…'
                          : widget.product == null
                          ? 'Publicar producto'
                          : 'Guardar cambios',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
