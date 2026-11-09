import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../data/marketplace_repository.dart';
import '../domain/marketplace_models.dart';
import 'order_pages.dart';
import 'product_form_page.dart';
import 'workspace_widgets.dart';

/// Ordenamiento del catálogo sincronizado con `Producto.java` en Spring Boot (`Pageable`).
enum CatalogSort {
  recent('Productos recientes', 'creadoEn,desc'),
  priceAsc('Menor precio', 'precioUnitario,asc'),
  priceDesc('Mayor precio', 'precioUnitario,desc');

  final String label;
  final String apiValue;
  const CatalogSort(this.label, this.apiValue);
}

/// Estado persistente del catálogo al cambiar de sección en la sesión.
class CatalogViewState {
  int page = 0;
  String? type;
  String? origin;
  String? country;
  num? minimumPrice;
  num? maximumPrice;
  CatalogSort sort = CatalogSort.recent;
  double scrollOffset = 0;
}

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
    this.viewState,
  });
  final MarketplaceRepository repository;
  final VoidCallback onSessionExpired;
  final CatalogViewState? viewState;
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final CatalogViewState _state = widget.viewState ?? CatalogViewState();
  late int _page = _state.page;
  int _revision = 0;
  late final ScrollController _scrollController = ScrollController(
    initialScrollOffset: _state.scrollOffset,
  )..addListener(_saveScrollOffset);
  final _filters = GlobalKey<FormState>();
  late final _origin = TextEditingController(text: _state.origin ?? ''),
      _country = TextEditingController(text: _state.country ?? ''),
      _minimum = TextEditingController(
        text: _state.minimumPrice?.toString() ?? '',
      ),
      _maximum = TextEditingController(
        text: _state.maximumPrice?.toString() ?? '',
      );
  late String? _draftType = _state.type,
      _type = _state.type,
      _appliedOrigin = _state.origin,
      _appliedCountry = _state.country;
  late num? _appliedMinimum = _state.minimumPrice,
      _appliedMaximum = _state.maximumPrice;

  late CatalogSort _currentSort = _state.sort;

  bool get _filtered =>
      _type != null ||
      _appliedOrigin != null ||
      _appliedCountry != null ||
      _appliedMinimum != null ||
      _appliedMaximum != null;

  void _saveScrollOffset() {
    if (_scrollController.hasClients) {
      _state.scrollOffset = _scrollController.offset;
    }
  }

  void _syncState() {
    _state
      ..page = _page
      ..type = _type
      ..origin = _appliedOrigin
      ..country = _appliedCountry
      ..minimumPrice = _appliedMinimum
      ..maximumPrice = _appliedMaximum
      ..sort = _currentSort;
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_saveScrollOffset)
      ..dispose();
    for (final c in [_origin, _country, _minimum, _maximum]) {
      c.dispose();
    }
    super.dispose();
  }

  num? _value(TextEditingController c) =>
      num.tryParse(c.text.trim().replaceAll(',', '.'));

  String? _price(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^\d{1,12}([.,]\d{1,2})?$').hasMatch(value.trim())) {
      return 'Ingresa un precio válido, con hasta dos decimales.';
    }
    return null;
  }

  void _apply() {
    if (!_filters.currentState!.validate()) return;
    setState(() {
      _type = _draftType;
      _page = 0;
      _revision++;
      _appliedOrigin = _origin.text.trim().isEmpty ? null : _origin.text.trim();
      _appliedCountry = _country.text.trim().isEmpty
          ? null
          : _country.text.trim();
      _appliedMinimum = _value(_minimum);
      _appliedMaximum = _value(_maximum);
      _syncState();
    });
  }

  void _clear() {
    for (final c in [_origin, _country, _minimum, _maximum]) {
      c.clear();
    }
    _draftType = null;
    _type = null;
    _appliedOrigin = null;
    _appliedCountry = null;
    _appliedMinimum = null;
    _appliedMaximum = null;
    setState(() {
      _page = 0;
      _revision++;
      _syncState();
    });
  }

  void _removeFilter(String filterType) {
    setState(() {
      switch (filterType) {
        case 'type':
          _type = null;
          _draftType = null;
        case 'origin':
          _appliedOrigin = null;
          _origin.clear();
        case 'country':
          _appliedCountry = null;
          _country.clear();
        case 'min':
          _appliedMinimum = null;
          _minimum.clear();
        case 'max':
          _appliedMaximum = null;
          _maximum.clear();
      }
      _page = 0;
      _revision++;
      _syncState();
    });
  }

  String _typeDisplay(String raw) => switch (raw) {
    'CAFE' => 'Café',
    'CACAO' => 'Cacao',
    _ => 'Variedad',
  };

  Future<void> _quickEditProduct(
    BuildContext context,
    Product product,
    Future<void> Function() reload,
  ) async {
    final priceController = TextEditingController(
      text: product.price.toString(),
    );
    final stockController = TextEditingController(
      text: product.availableAmount.toString(),
    );
    final formKey = GlobalKey<FormState>();
    String? priceError;
    String? stockError;
    var saving = false;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edición rápida'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(product.name, style: Theme.of(ctx).textTheme.bodyMedium),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('quick-price-input'),
                  controller: priceController,
                  readOnly: saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Precio por presentación',
                    errorText: priceError,
                  ),
                  validator: (val) {
                    final parsed = num.tryParse(
                      (val ?? '').trim().replaceAll(',', '.'),
                    );
                    if (parsed == null || parsed <= 0) {
                      return 'Ingresa un precio válido mayor que cero.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('quick-stock-input'),
                  controller: stockController,
                  readOnly: saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Cantidad disponible (Stock)',
                    errorText: stockError,
                  ),
                  validator: (val) {
                    final parsed = num.tryParse(
                      (val ?? '').trim().replaceAll(',', '.'),
                    );
                    if (parsed == null || parsed < 0) {
                      return 'Ingresa una cantidad disponible válida (>= 0).';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const Key('quick-price-save'),
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() {
                        priceError = null;
                        stockError = null;
                      });
                      if (!formKey.currentState!.validate()) return;
                      final newPrice = double.parse(
                        priceController.text.trim().replaceAll(',', '.'),
                      );
                      final newStock = num.parse(
                        stockController.text.trim().replaceAll(',', '.'),
                      );
                      setDialogState(() => saving = true);
                      try {
                        await widget.repository.saveProduct({
                          'nombre': product.name,
                          'tipo': product.type,
                          'variedad': product.variety ?? '',
                          'cantidadUnitaria': product.unitAmount,
                          'unidadCantidad': product.unit,
                          'cantidadDisponible': newStock,
                          'lugarOrigen': product.origin,
                          'precioUnitario': newPrice,
                          'disponible': newStock > 0,
                        }, id: product.id);
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        if (!ctx.mounted) return;
                        setDialogState(() {
                          saving = false;
                          if (e is ApiException) {
                            priceError =
                                e.fieldErrors['precioUnitario'] ??
                                (e.fieldErrors['cantidadDisponible'] == null
                                    ? e.message
                                    : null);
                            stockError = e.fieldErrors['cantidadDisponible'];
                          } else {
                            priceError = 'No pudimos actualizar el producto.';
                          }
                        });
                      }
                    },
              child: Text(saving ? 'Guardando…' : 'Guardar'),
            ),
          ],
        ),
      ),
    );

    priceController.dispose();
    stockController.dispose();
    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto actualizado con éxito'),
          backgroundColor: Colors.green,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _page = 0;
        _revision++;
        _syncState();
      });
      await reload();
    }
  }

  Widget _filterBox() => Card.outlined(
    child: ExpansionTile(
      key: ValueKey('filters-$_revision'),
      title: Text(_filtered ? 'Filtros activos' : 'Filtrar productos'),
      initiallyExpanded: false,
      childrenPadding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _filters,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('filter-type'),
                initialValue: _draftType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo de producto',
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'CAFE', child: Text('Café')),
                  DropdownMenuItem(value: 'CACAO', child: Text('Cacao')),
                  DropdownMenuItem(value: 'VARIEDAD', child: Text('Variedad')),
                ],
                onChanged: (v) => _draftType = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('filter-country'),
                controller: _country,
                decoration: const InputDecoration(labelText: 'País de origen'),
                validator: (v) => (v?.trim().length ?? 0) > 80
                    ? 'Usa hasta 80 caracteres.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('filter-origin'),
                controller: _origin,
                decoration: const InputDecoration(
                  labelText: 'Ciudad o región de origen',
                ),
                validator: (v) => (v?.trim().length ?? 0) > 100
                    ? 'Usa hasta 100 caracteres.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('filter-minimum'),
                controller: _minimum,
                decoration: const InputDecoration(labelText: 'Precio mínimo'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _price,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('filter-maximum'),
                controller: _maximum,
                decoration: const InputDecoration(labelText: 'Precio máximo'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    _price(v) ??
                    (_value(_minimum) != null &&
                            _value(_maximum) != null &&
                            _value(_minimum)! > _value(_maximum)!
                        ? 'El máximo debe ser igual o mayor al mínimo.'
                        : null),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton(
                    key: const Key('filter-apply'),
                    onPressed: _apply,
                    child: const Text('Aplicar filtros'),
                  ),
                  TextButton(
                    key: const Key('filter-clear'),
                    onPressed: _clear,
                    child: const Text('Limpiar filtros'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildFilterChips() {
    final chips = <Widget>[
      if (_type != null)
        InputChip(
          key: const Key('chip-filter-type'),
          label: Text('Tipo: ${_typeDisplay(_type!)}'),
          onDeleted: () => _removeFilter('type'),
        ),
      if (_appliedCountry != null)
        InputChip(
          key: const Key('chip-filter-country'),
          label: Text('País: $_appliedCountry'),
          onDeleted: () => _removeFilter('country'),
        ),
      if (_appliedOrigin != null)
        InputChip(
          key: const Key('chip-filter-origin'),
          label: Text('Origen: $_appliedOrigin'),
          onDeleted: () => _removeFilter('origin'),
        ),
      if (_appliedMinimum != null)
        InputChip(
          key: const Key('chip-filter-min'),
          label: Text('Mín: ${number(_appliedMinimum!)}'),
          onDeleted: () => _removeFilter('min'),
        ),
      if (_appliedMaximum != null)
        InputChip(
          key: const Key('chip-filter-max'),
          label: Text('Máx: ${number(_appliedMaximum!)}'),
          onDeleted: () => _removeFilter('max'),
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RemoteView<ProductPage>(
      key: ValueKey('$_page-$_revision-${_currentSort.name}'),
      load: () => widget.repository.products(
        page: _page,
        type: _type,
        origin: _appliedOrigin,
        country: _appliedCountry,
        minimumPrice: _appliedMinimum,
        maximumPrice: _appliedMaximum,
        sort: _currentSort.apiValue,
      ),
      onSessionExpired: widget.onSessionExpired,
      builder: (data, reload) => PageBody(
        controller: _scrollController,
        onRefresh: reload,
        children: [
          PageHeading(
            title: widget.repository.isSeller
                ? 'Mis productos'
                : 'Explora los productos',
            description: widget.repository.isSeller
                ? 'Publica y administra tus productos.'
                : 'Conoce el origen, la disponibilidad y al vendedor.',
            onRefresh: reload,
          ),
          if (widget.repository.isSeller)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  key: const Key('product-create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Publicar producto'),
                  onPressed: () async {
                    final saved = await Navigator.of(context).push<Product>(
                      MaterialPageRoute(
                        builder: (_) => ProductFormPage(
                          repository: widget.repository,
                          onSessionExpired: widget.onSessionExpired,
                        ),
                      ),
                    );
                    if (saved != null && mounted) {
                      setState(() {
                        _page = 0;
                        _revision++;
                        _syncState();
                      });
                    }
                  },
                ),
              ),
            ),
          _filterBox(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildFilterChips()),
              PopupMenuButton<CatalogSort>(
                key: const Key('catalog-sort-button'),
                tooltip: 'Ordenar catálogo',
                initialValue: _currentSort,
                onSelected: (CatalogSort newSort) {
                  if (_currentSort == newSort) return;
                  setState(() {
                    _currentSort = newSort;
                    _page = 0;
                    _revision++;
                    _syncState();
                  });
                },
                itemBuilder: (context) => [
                  for (final sort in CatalogSort.values)
                    PopupMenuItem(value: sort, child: Text(sort.label)),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort, size: 20),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Ordenar: ${_currentSort.label}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (data.items.isEmpty)
            EmptyMessage(
              title: _filtered
                  ? 'Sin resultados para estos filtros'
                  : 'No hay productos para mostrar',
              message: _filtered
                  ? 'Prueba con otros criterios o limpia los filtros.'
                  : widget.repository.isSeller
                  ? 'Publica tu primer producto para que aparezca aquí.'
                  : 'Vuelve a consultar más tarde.',
              action: _filtered
                  ? OutlinedButton(
                      onPressed: _clear,
                      child: const Text('Limpiar filtros'),
                    )
                  : null,
            ),
          for (final item in data.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card.outlined(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await openProduct(
                      context,
                      widget.repository,
                      item.id,
                      widget.onSessionExpired,
                    );
                    if (context.mounted) await reload();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const ExcludeSemantics(
                              child: Icon(Icons.eco_outlined),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            if (widget.repository.isSeller)
                              IconButton(
                                key: Key('product-quick-edit-${item.id}'),
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                tooltip: 'Editar precio y stock',
                                onPressed: () =>
                                    _quickEditProduct(context, item, reload),
                              ),
                            const ExcludeSemantics(
                              child: Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${item.typeLabel} · ${item.origin} · ${item.seller.country ?? "País sin especificar"}',
                        ),
                        if (item.variety?.isNotEmpty == true)
                          Text('Variedad: ${item.variety}'),
                        const SizedBox(height: 8),
                        Text('Precio por presentación: ${number(item.price)}'),
                        Text(
                          'Disponible: ${number(item.availableAmount)} unidades${item.available ? "" : " · Fuera del catálogo"}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (data.total > 0) ...[
            Text(
              '${number(data.total)} productos · Página ${data.page + 1} de ${data.totalPages}',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              children: [
                OutlinedButton(
                  onPressed: _page > 0
                      ? () => setState(() {
                          _page--;
                          _syncState();
                        })
                      : null,
                  child: const Text('Anterior'),
                ),
                OutlinedButton(
                  onPressed: _page + 1 < data.totalPages
                      ? () => setState(() {
                          _page++;
                          _syncState();
                        })
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
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
                    _Detail('Tipo de producto', product.typeLabel),
                    _Detail(
                      'Variedad',
                      product.variety?.isNotEmpty == true
                          ? product.variety!
                          : 'Sin especificar',
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
                  ],
                ),
              ),
            ),
            if (repository.ownsProduct(product))
              ProductManageActions(
                repository: repository,
                product: product,
                onSessionExpired: onSessionExpired,
                onSaved: reload,
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
                          final viewOrder = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Solicitud registrada'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cantidad: ${number(order.quantity)}'),
                                  Text(
                                    'Precio aplicado: ${order.unitPrice == null ? "Revisa la orden" : number(order.unitPrice!)}',
                                  ),
                                  Text(
                                    'Total confirmado: ${order.total == null ? "Revisa la orden" : number(order.total!)}',
                                  ),
                                  const Text('Estado: Solicitada'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Cerrar'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Ver orden'),
                                ),
                              ],
                            ),
                          );
                          if (!context.mounted) return;
                          if (viewOrder == true) {
                            await openOrder(
                              context,
                              repository,
                              order.id,
                              onSessionExpired,
                            );
                          }
                          if (!context.mounted) return;
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
  Widget build(BuildContext context) {
    final validQuantity =
        (quantity != null &&
            quantity! > 0 &&
            quantity! <= widget.product.availableAmount)
        ? quantity!
        : (quantity ?? 0);
    final estimatedTotal =
        (validQuantity > 0 ? validQuantity : 0) * widget.product.price;
    final sellerLabel =
        widget.product.seller.company ?? widget.product.seller.name;

    return PopScope(
      canPop: !_sending,
      child: Scaffold(
        appBar: AppBar(title: const Text('Iniciar solicitud')),
        body: SafeArea(
          child: PageBody(
            children: [
              PageHeading(
                title: widget.product.name,
                description: 'Solicitud a $sellerLabel.',
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
              Card.outlined(
                key: const Key('order-preview-summary'),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen previo de la solicitud',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Producto: ${widget.product.name} (${widget.product.typeLabel})',
                      ),
                      const SizedBox(height: 4),
                      Text('Vendedor: $sellerLabel'),
                      const SizedBox(height: 4),
                      Text('Origen: ${widget.product.origin}'),
                      const SizedBox(height: 4),
                      Text(
                        'Presentación: ${number(widget.product.unitAmount)} ${widget.product.unitLabel} por unidad',
                      ),
                      const SizedBox(height: 4),
                      Text('Precio unitario: ${number(widget.product.price)}'),
                      const SizedBox(height: 4),
                      Text(
                        'Cantidad solicitada: ${number(validQuantity > 0 ? validQuantity : 0)} unidades',
                      ),
                      const Divider(height: 24),
                      Text(
                        'Total de referencia: ${number(estimatedTotal)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
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
}

class ProductManageActions extends StatefulWidget {
  const ProductManageActions({
    super.key,
    required this.repository,
    required this.product,
    required this.onSaved,
    required this.onSessionExpired,
  });
  final MarketplaceRepository repository;
  final Product product;
  final Future<void> Function() onSaved;
  final VoidCallback onSessionExpired;
  @override
  State<ProductManageActions> createState() => _ProductManageActionsState();
}

class _ProductManageActionsState extends State<ProductManageActions> {
  bool _deleting = false;
  String? _error;
  Future<void> _delete() async {
    if (_deleting) return;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: const Text(
          'Solo se puede eliminar si no tiene órdenes asociadas. Puedes desactivarlo desde Editar producto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (!mounted || accepted != true) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await widget.repository.deleteProduct(widget.product.id);
      if (mounted) Navigator.pop(context);
    } catch (failure) {
      if (!mounted) return;
      if (failure is ApiException && failure.statusCode == 401) {
        widget.onSessionExpired();
        return;
      }
      setState(() {
        _deleting = false;
        _error = failure is ApiException
            ? failure.message
            : 'No pudimos eliminar el producto.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 24),
      FilledButton.icon(
        key: const Key('product-edit'),
        onPressed: _deleting
            ? null
            : () async {
                final saved = await Navigator.of(context).push<Product>(
                  MaterialPageRoute(
                    builder: (_) => ProductFormPage(
                      repository: widget.repository,
                      product: widget.product,
                      onSessionExpired: widget.onSessionExpired,
                    ),
                  ),
                );
                if (saved != null && mounted) await widget.onSaved();
              },
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Editar producto'),
      ),
      TextButton(
        onPressed: _deleting ? null : _delete,
        child: Text(_deleting ? 'Eliminando…' : 'Eliminar producto'),
      ),
      if (_error != null) InfoNotice(_error!, isError: true),
    ],
  );
}
