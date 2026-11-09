import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../data/marketplace_repository.dart';
import '../domain/marketplace_models.dart';
import 'product_pages.dart';
import 'workspace_widgets.dart';

/// Ordenamiento de órdenes sincronizado con `Orden.java` en Spring Boot (`Pageable`).
enum OrderSort {
  recent('Más recientes', null),
  oldest('Más antiguas', 'creadoEn,asc'),
  amountDesc('Mayor importe', 'precioTotal,desc'),
  amountAsc('Menor importe', 'precioTotal,asc'),
  status('Estado', 'estado,asc');

  final String label;
  final String? apiValue;
  const OrderSort(this.label, this.apiValue);
}

/// Estado persistente de la vista de órdenes al cambiar de sección en la sesión.
class OrdersViewState {
  bool history = false;
  int page = 0;
  OrderSort sort = OrderSort.recent;
  double scrollOffset = 0;
}

Future<void> openOrder(
  BuildContext context,
  MarketplaceRepository repository,
  String id,
  VoidCallback onSessionExpired,
) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => OrderDetailPage(
      repository: repository,
      orderId: id,
      onSessionExpired: onSessionExpired,
    ),
  ),
);

class OrdersReadPage extends StatefulWidget {
  const OrdersReadPage({
    super.key,
    required this.repository,
    required this.onSessionExpired,
    this.viewState,
  });
  final MarketplaceRepository repository;
  final VoidCallback onSessionExpired;
  final OrdersViewState? viewState;
  @override
  State<OrdersReadPage> createState() => _OrdersReadPageState();
}

class _OrdersReadPageState extends State<OrdersReadPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final OrdersViewState _state = widget.viewState ?? OrdersViewState();
  late bool _history = _state.history;
  late int _page = _state.page;
  int _revision = 0;
  late OrderSort _currentSort = _state.sort;
  late final ScrollController _scrollController = ScrollController(
    initialScrollOffset: _state.scrollOffset,
  )..addListener(_saveScrollOffset);

  void _saveScrollOffset() {
    if (_scrollController.hasClients) {
      _state.scrollOffset = _scrollController.offset;
    }
  }

  void _syncState() {
    _state
      ..history = _history
      ..page = _page
      ..sort = _currentSort;
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_saveScrollOffset)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RemoteView<OrderPage>(
      key: ValueKey('$_history-$_page-$_revision-${_currentSort.name}'),
      load: () => widget.repository.orderPage(
        page: _page,
        history: _history,
        sort: _currentSort.apiValue,
      ),
      onSessionExpired: widget.onSessionExpired,
      builder: (data, reload) => PageBody(
        controller: _scrollController,
        onRefresh: reload,
        children: [
          PageHeading(
            title: widget.repository.isSeller
                ? 'Órdenes recibidas'
                : 'Mis órdenes',
            description: _history
                ? 'Órdenes entregadas o rechazadas de tu cuenta.'
                : 'Solicitudes pendientes y órdenes en proceso.',
            onRefresh: reload,
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('En curso')),
                  ButtonSegment(value: true, label: Text('Historial')),
                ],
                selected: {_history},
                onSelectionChanged: (selection) => setState(() {
                  _history = selection.single;
                  _page = 0;
                  _syncState();
                }),
              ),
              PopupMenuButton<OrderSort>(
                key: const Key('orders-sort-button'),
                tooltip: 'Ordenar órdenes',
                initialValue: _currentSort,
                onSelected: (OrderSort newSort) {
                  if (_currentSort == newSort) return;
                  setState(() {
                    _currentSort = newSort;
                    _page = 0;
                    _revision++;
                    _syncState();
                  });
                },
                itemBuilder: (context) => [
                  for (final sort in OrderSort.values)
                    PopupMenuItem(value: sort, child: Text(sort.label)),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sort_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ordenar: ${_currentSort.label}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (data.items.isEmpty)
            const EmptyMessage(
              title: 'No hay órdenes en esta sección',
              message:
                  'Aquí aparecerán las órdenes correspondientes a tu cuenta.',
            ),
          for (final order in data.items)
            OrderRow(
              order: order,
              onTap: () async {
                await openOrder(
                  context,
                  widget.repository,
                  order.id,
                  widget.onSessionExpired,
                );
                if (context.mounted) await reload();
              },
            ),
          if (data.total > 0) ...[
            Text(
              '${number(data.total)} órdenes · Página ${_page + 1} de ${data.totalPages}',
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

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.repository,
    required this.orderId,
    required this.onSessionExpired,
    this.pollInterval = const Duration(seconds: 5),
  });
  final MarketplaceRepository repository;
  final String orderId;
  final VoidCallback onSessionExpired;
  final Duration pollInterval;
  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _sending = false;
  String? _error;
  String? _concurrentNotice;
  OrderSummary? _latestOrder;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  bool _isActiveState(String state) =>
      state != 'ENTREGADA' && state != 'RECHAZADA';

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(widget.pollInterval, (_) => _pollOrderUpdate());
  }

  Future<void> _pollOrderUpdate() async {
    if (!mounted || _sending) return;
    final current = _latestOrder;
    if (current != null && !_isActiveState(current.state)) {
      _pollTimer?.cancel();
      return;
    }
    try {
      final updated = await widget.repository.order(widget.orderId);
      if (!mounted || _sending) return;
      final previousState = _latestOrder?.state;
      final changed = previousState != null && previousState != updated.state;
      if (changed || _latestOrder?.events.length != updated.events.length) {
        setState(() {
          _latestOrder = updated;
          if (changed) {
            _concurrentNotice =
                'El estado de la orden se actualizó automáticamente a ${statusLabel(updated.state)}.';
          }
        });
      }
      if (!_isActiveState(updated.state)) {
        _pollTimer?.cancel();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401 && mounted) {
        _pollTimer?.cancel();
        widget.onSessionExpired();
      }
    } catch (_) {
      // Ignora fallos silenciosos durante el refresco automático.
    }
  }

  Future<OrderSummary> _loadOrder() async {
    final loaded = await widget.repository.order(widget.orderId);
    _latestOrder = loaded;
    if (!_isActiveState(loaded.state)) {
      _pollTimer?.cancel();
    }
    return loaded;
  }

  Future<void> _advance(
    OrderSummary order,
    String action,
    Future<void> Function() reload,
  ) async {
    if (_sending) return;
    if (action == 'rechazar' || action == 'entregar') {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            action == 'rechazar'
                ? '¿Rechazar solicitud?'
                : '¿Confirmar entrega?',
          ),
          content: const Text(
            'La orden pasará al historial y se conservará su información.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
      if (!mounted || accepted != true) return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _concurrentNotice = null;
    });
    try {
      final updated = await widget.repository.advanceOrder(order.id, action);
      if (!mounted) return;
      _latestOrder = updated;
      await reload();
    } catch (failure) {
      if (!mounted) return;
      if (failure is ApiException && failure.statusCode == 401) {
        widget.onSessionExpired();
        return;
      }
      if (failure is ApiException && failure.statusCode == 409) {
        setState(() {
          _error =
              'Acciones actualizadas: esta acción ya no está disponible porque la orden cambió desde otra sesión.';
        });
        await reload();
        return;
      }
      setState(
        () => _error = failure is ApiException
            ? failure.message
            : 'No pudimos actualizar la orden. Reintenta.',
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_sending,
    child: Scaffold(
      appBar: AppBar(title: const Text('Detalle de la orden')),
      body: SafeArea(
        child: RemoteView<OrderSummary>(
          load: _loadOrder,
          onSessionExpired: widget.onSessionExpired,
          builder: (loadedOrder, reload) {
            final order = _latestOrder ?? loadedOrder;
            return PageBody(
              onRefresh: _sending
                  ? null
                  : () async {
                      setState(() => _concurrentNotice = null);
                      await reload();
                    },
              children: [
                PageHeading(
                  title: order.productName,
                  description: 'Estado: ${statusLabel(order.state)}',
                  onRefresh: _sending ? null : reload,
                ),
                if (_concurrentNotice != null) ...[
                  InfoNotice(_concurrentNotice!),
                  const SizedBox(height: 16),
                ],
                Card.outlined(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Total: ${order.total == null ? "Sin información" : number(order.total!)}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Cantidad: ${number(order.quantity)} unidades'),
                        const SizedBox(height: 10),
                        Text(
                          'Precio aplicado por unidad: ${order.unitPrice == null ? "Sin información" : number(order.unitPrice!)}',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1),
                        ),
                        Text(
                          'Comprador: ${order.buyer?.name ?? "Sin información"}',
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Vendedor: ${order.seller?.company ?? order.seller?.name ?? "Sin información"}',
                        ),
                        const SizedBox(height: 14),
                        SelectableText(
                          'Orden: ${order.id}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SectionTitle('Progreso de la orden'),
                _OrderProgressIndicator(order: order),
                const SectionTitle('Seguimiento de la orden'),
                for (final (label, time) in order.events)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const ExcludeSemantics(
                      child: Icon(Icons.check_circle_outline),
                    ),
                    title: Text(label),
                    subtitle: Text(date(time)),
                  ),
                if (_error != null) ...[
                  InfoNotice(_error!, isError: true),
                  TextButton(
                    onPressed: reload,
                    child: const Text('Actualizar orden'),
                  ),
                ],
                if (widget.repository.isSeller &&
                    order.seller?.id == widget.repository.session.userId) ...[
                  if (order.nextAction case final action?)
                    FilledButton(
                      key: const Key('order-advance'),
                      onPressed: _sending
                          ? null
                          : () => _advance(order, action, reload),
                      child: Text(
                        _sending ? 'Actualizando…' : order.nextActionLabel!,
                      ),
                    ),
                  if (order.state == 'SOLICITADA')
                    TextButton(
                      key: const Key('order-reject'),
                      onPressed: _sending
                          ? null
                          : () => _advance(order, 'rechazar', reload),
                      child: const Text('Rechazar solicitud'),
                    ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _sending
                      ? null
                      : () => openProduct(
                          context,
                          widget.repository,
                          order.productId,
                          widget.onSessionExpired,
                        ),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Ver producto'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'El precio y total corresponden al momento en que se creó la solicitud.',
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

enum _StepStatus { completed, current, pending, rejected }

class _OrderProgressIndicator extends StatelessWidget {
  const _OrderProgressIndicator({required this.order});

  final OrderSummary order;

  static const _stages = [
    (code: 'SOLICITADA', title: '1. Solicitada'),
    (code: 'ACEPTADA', title: '2. Confirmada'),
    (code: 'EN_PREPARACION', title: '3. En preparación'),
    (code: 'ENVIADA', title: '4. En tránsito'),
    (code: 'ENTREGADA', title: '5. Entregada'),
  ];

  int _stageIndex(String state) => switch (state) {
    'SOLICITADA' => 0,
    'ACEPTADA' || 'CONFIRMADA' => 1,
    'EN_PREPARACION' => 2,
    'ENVIADA' || 'EN_TRANSITO' => 3,
    'ENTREGADA' => 4,
    _ => -1,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isRejected = order.state == 'RECHAZADA';
    final activeIdx = _stageIndex(order.state);

    return Card.outlined(
      key: const Key('order-progress-indicator'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRejected) ...[
              Row(
                children: [
                  Icon(Icons.cancel_outlined, color: colors.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Solicitud rechazada — proceso finalizado',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            for (var i = 0; i < _stages.length; i++) ...[
              _buildStageRow(
                context,
                title: _stages[i].title,
                status: isRejected
                    ? (i == 0 ? _StepStatus.completed : _StepStatus.rejected)
                    : (i < activeIdx || order.state == 'ENTREGADA'
                          ? _StepStatus.completed
                          : (i == activeIdx
                                ? _StepStatus.current
                                : _StepStatus.pending)),
              ),
              if (i < _stages.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStageRow(
    BuildContext context, {
    required String title,
    required _StepStatus status,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final (icon, iconColor, statusText, isBold) = switch (status) {
      _StepStatus.completed => (
        Icons.check_circle_rounded,
        colors.primary,
        'Completada',
        false,
      ),
      _StepStatus.current => (
        Icons.radio_button_checked_rounded,
        colors.primary,
        'Etapa actual',
        true,
      ),
      _StepStatus.pending => (
        Icons.radio_button_unchecked_rounded,
        colors.onSurfaceVariant,
        'Pendiente',
        false,
      ),
      _StepStatus.rejected => (
        Icons.remove_circle_outline_rounded,
        colors.outline,
        'Cancelada',
        false,
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Icon(icon, size: 22, color: iconColor)),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: status == _StepStatus.pending ||
                          status == _StepStatus.rejected
                      ? colors.onSurfaceVariant
                      : colors.onSurface,
                ),
              ),
              Text(
                statusText,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: status == _StepStatus.current
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
