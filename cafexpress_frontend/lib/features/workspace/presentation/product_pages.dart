import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../data/marketplace_repository.dart';
import '../domain/marketplace_models.dart';
import 'workspace_widgets.dart';

Future<void> openProduct(
  BuildContext context,
  MarketplaceRepository repository,
  String id,
  VoidCallback onSessionExpired,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => ProductDetailPage(
      repository: repository,
      productId: id,
      onSessionExpired: onSessionExpired,
    ),
  ),
);

class ProductListPage extends StatefulWidget {
  const ProductListPage({
    super.key,
    required this.repository,
    required this.onSessionExpired,
  });
  final MarketplaceRepository repository;
  final VoidCallback onSessionExpired;
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  int _page = 0;
  @override
  Widget build(BuildContext context) => RemoteView<ProductPage>(
    key: ValueKey(_page),
    load: () => widget.repository.products(page: _page),
    onSessionExpired: widget.onSessionExpired,
    builder: (data, reload) => PageBody(
      onRefresh: reload,
      children: [
        PageHeading(
          title: widget.repository.isSeller
              ? 'Mis productos'
              : 'Explora los productos',
          description: widget.repository.isSeller
              ? 'Consulta tus productos y la información que ven los compradores.'
              : 'Conoce el origen, la disponibilidad y al vendedor antes de solicitar un producto.',
          onRefresh: reload,
        ),
        if (data.items.isEmpty)
          EmptyMessage(
            title: widget.repository.isSeller
                ? 'Aún no tienes productos'
                : 'No hay productos disponibles',
            message: widget.repository.isSeller
                ? 'Los productos asociados a tu cuenta aparecerán aquí.'
                : 'Vuelve a consultar más tarde para conocer las nuevas publicaciones.',
          ),
        for (final item in data.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card.outlined(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => openProduct(
                  context,
                  widget.repository,
                  item.id,
                  widget.onSessionExpired,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              Icons.eco_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const ExcludeSemantics(
                            child: Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${item.origin} · ${item.seller.company ?? item.seller.name}',
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          Text('Precio por unidad: ${number(item.price)}'),
                          Text(
                            'Disponible: ${number(item.availableAmount)} unidades',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (data.total > 0) ...[
          const SizedBox(height: 16),
          Text(
            '${number(data.total)} productos · Página ${data.page + 1} de ${data.totalPages}',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _page > 0 ? () => setState(() => _page--) : null,
                child: const Text('Anterior'),
              ),
              OutlinedButton(
                onPressed: _page + 1 < data.totalPages
                    ? () => setState(() => _page++)
                    : null,
                child: const Text('Siguiente'),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({
    super.key,
    required this.repository,
    required this.productId,
    required this.onSessionExpired,
  });
  final MarketplaceRepository repository;
  final String productId;
  final VoidCallback onSessionExpired;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle del producto')),
    body: SafeArea(
      child: RemoteView<Product>(
        load: () => repository.product(productId),
        onSessionExpired: onSessionExpired,
        builder: (product, reload) => PageBody(
          onRefresh: reload,
          children: [
            PageHeading(
              title: product.name,
              description: product.origin,
              onRefresh: reload,
            ),
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precio por unidad',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      number(product.price),
                      style: Theme.of(context).textTheme.displaySmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 24),
                    _Detail(
                      'Presentación',
                      '${number(product.unitAmount)} ${product.unitLabel} por unidad',
                    ),
                    _Detail(
                      'Cantidad disponible',
                      '${number(product.availableAmount)} unidades',
                    ),
                    _Detail('Origen del producto', product.origin),
                    _Detail(
                      'Disponibilidad',
                      product.canOrder
                          ? 'Disponible para solicitar'
                          : 'No disponible',
                    ),
                  ],
                ),
              ),
            ),
            const SectionTitle('Conoce al vendedor'),
            Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Detail('Vendedor', product.seller.name),
                    _Detail(
                      'Empresa o productor',
                      product.seller.company ?? 'Sin información',
                    ),
                    _Detail(
                      'País de origen',
                      product.seller.country ?? 'Sin información',
                    ),
                    _Detail('Correo de contacto', product.seller.email),
                    _Detail(
                      'Verificación',
                      product.seller.verification ?? 'Sin estado informado',
                    ),
                  ],
                ),
              ),
            ),
            if (!repository.isSeller) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('product-start-order'),
                onPressed: !product.canOrder
                    ? null
                    : () async {
                        final order = await Navigator.of(context)
                            .push<OrderSummary>(
                              MaterialPageRoute(
                                builder: (_) => StartOrderPage(
                                  repository: repository,
                                  product: product,
                                ),
                              ),
                            );
                        if (context.mounted && order != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Solicitud registrada. Estado: Solicitada.',
                              ),
                            ),
                          );
                          await reload();
                        }
                      },
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Iniciar solicitud'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Consulta la información del vendedor antes de solicitar. Esta acción no realiza pagos.',
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Semantics(
      container: true,
      label: '$label: $value',
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
          SelectableText(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    ),
  );
}

class StartOrderPage extends StatefulWidget {
  const StartOrderPage({
    super.key,
    required this.repository,
    required this.product,
  });
  final MarketplaceRepository repository;
  final Product product;
  @override
  State<StartOrderPage> createState() => _StartOrderPageState();
}

class _StartOrderPageState extends State<StartOrderPage> {
  final _form = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  bool _sending = false, _submitted = false;
  String? _error;
  num? get quantity => num.tryParse(_quantity.text.trim().replaceAll(',', '.'));
  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    if (value == null ||
        !RegExp(r'^\d+([.,]\d{1,3})?$').hasMatch(value.trim()) ||
        quantity == null ||
        quantity! <= 0) {
      return 'Escribe una cantidad mayor que cero, con hasta tres decimales.';
    }
    if (quantity! > widget.product.availableAmount) {
      return 'La cantidad supera la disponibilidad.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_sending) return;
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      final order = await widget.repository.startOrder(
        widget.product.id,
        quantity!,
      );
      if (!mounted) return;
      setState(() => _sending = false);
      Navigator.of(context).pop(order);
    } catch (error) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = error is ApiException
              ? error.message
              : 'No pudimos enviar la solicitud. Inténtalo de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_sending,
    child: Scaffold(
      appBar: AppBar(title: const Text('Iniciar solicitud')),
      body: SafeArea(
        child: PageBody(
          children: [
            PageHeading(
              title: widget.product.name,
              description:
                  'Solicitud a ${widget.product.seller.company ?? widget.product.seller.name}.',
            ),
            Text(
              'Disponible: ${number(widget.product.availableAmount)} unidades.',
            ),
            const SizedBox(height: 24),
            Form(
              key: _form,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: TextFormField(
                key: const Key('order-quantity'),
                controller: _quantity,
                readOnly: _sending,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Cantidad de unidades',
                ),
                validator: _validate,
                onFieldSubmitted: (_) => _submit(),
                onChanged: (_) => setState(() => _error = null),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Total de referencia: ${number((quantity ?? 0) * widget.product.price)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Esta solicitud queda pendiente de aceptación por el vendedor. No realiza pagos.',
            ),
            if (_error != null) ...[
              const SizedBox(height: 24),
              InfoNotice(_error!, isError: true),
            ],
            const SizedBox(height: 32),
            FilledButton(
              key: const Key('order-submit'),
              onPressed: _sending ? null : _submit,
              child: Text(_sending ? 'Enviando…' : 'Enviar solicitud'),
            ),
          ],
        ),
      ),
    ),
  );
}
