import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../data/marketplace_repository.dart';
import '../domain/marketplace_models.dart';
import 'product_pages.dart';
import 'workspace_widgets.dart';

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
  });
  final MarketplaceRepository repository;
  final VoidCallback onSessionExpired;
  @override
  State<OrdersReadPage> createState() => _OrdersReadPageState();
}

class _OrdersReadPageState extends State<OrdersReadPage> {
  bool _history = false;
  int _page = 0;
  @override
  Widget build(BuildContext context) => RemoteView<OrderPage>(
    key: ValueKey('$_history-$_page'),
    load: () => widget.repository.orderPage(page: _page, history: _history),
    onSessionExpired: widget.onSessionExpired,
    builder: (data, reload) => PageBody(
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
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('En curso')),
            ButtonSegment(value: true, label: Text('Historial')),
          ],
          selected: {_history},
          onSelectionChanged: (selection) => setState(() {
            _history = selection.single;
            _page = 0;
          }),
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

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.repository,
    required this.orderId,
    required this.onSessionExpired,
  });
  final MarketplaceRepository repository;
  final String orderId;
  final VoidCallback onSessionExpired;
  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _sending = false;
  String? _error;
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
    });
    try {
      await widget.repository.advanceOrder(order.id, action);
      if (mounted) await reload();
    } catch (failure) {
      if (!mounted) return;
      if (failure is ApiException && failure.statusCode == 401) {
        widget.onSessionExpired();
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
          load: () => widget.repository.order(widget.orderId),
          onSessionExpired: widget.onSessionExpired,
          builder: (order, reload) => PageBody(
            onRefresh: _sending ? null : reload,
            children: [
              PageHeading(
                title: order.productName,
                description: 'Estado: ${statusLabel(order.state)}',
                onRefresh: _sending ? null : reload,
              ),
              Card.outlined(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cantidad: ${number(order.quantity)} unidades'),
                      const SizedBox(height: 12),
                      Text(
                        'Precio aplicado por unidad: ${order.unitPrice == null ? "Sin información" : number(order.unitPrice!)}',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Total: ${order.total == null ? "Sin información" : number(order.total!)}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Comprador: ${order.buyer?.name ?? "Sin información"}',
                      ),
                      Text(
                        'Vendedor: ${order.seller?.company ?? order.seller?.name ?? "Sin información"}',
                      ),
                      const SizedBox(height: 16),
                      SelectableText('Orden: ${order.id}'),
                    ],
                  ),
                ),
              ),
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
          ),
        ),
      ),
    ),
  );
}
