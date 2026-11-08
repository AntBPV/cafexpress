import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';

import '../data/marketplace_repository.dart';
import '../domain/marketplace_models.dart';
import 'product_pages.dart';
import 'workspace_widgets.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.repository,
    required this.onSelect,
    required this.onSessionExpired,
  });
  final MarketplaceRepository repository;
  final ValueChanged<int> onSelect;
  final VoidCallback onSessionExpired;
  @override
  Widget build(BuildContext context) => RemoteView<DashboardData>(
    load: repository.dashboard,
    onSessionExpired: onSessionExpired,
    builder: (data, reload) => PageBody(
      onRefresh: reload,
      children: [
        PageHeading(
          title: 'Hola, ${data.profile.name}',
          description: data.profile.isSeller
              ? 'Tus productos, solicitudes y señales del clima, en un solo lugar.'
              : 'Tus solicitudes y las novedades de los productos que te interesan.',
          onRefresh: reload,
        ),
        Text(
          'Panel del ${data.profile.roleLabel.toLowerCase()} · Actualizado ${date(data.updated)}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 24),
        if (data.profile.isSeller && !data.profile.isComplete) ...[
          const InfoNotice(
            'Completa tu perfil para que los compradores conozcan tu empresa o productor y tu país.',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onSelect(4),
              icon: const Icon(Icons.person_outline),
              label: const Text('Completar mi perfil'),
            ),
          ),
          const SizedBox(height: 16),
        ],
        LayoutBuilder(
          builder: (context, bounds) {
            final stats = [
              if (data.profile.isSeller)
                (
                  'Productos activos',
                  data.activeProducts,
                  Icons.inventory_2_outlined,
                ),
              (
                'Órdenes activas',
                data.activeOrders,
                Icons.receipt_long_outlined,
              ),
              (
                data.profile.isSeller ? 'Por responder' : 'Esperando respuesta',
                data.byState['SOLICITADA'] ?? 0,
                Icons.schedule_rounded,
              ),
            ];
            final width = bounds.maxWidth >= 620
                ? (bounds.maxWidth - 12 * (stats.length - 1)) / stats.length
                : bounds.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (label, count, icon) in stats)
                  SizedBox(
                    width: width,
                    child: Card.outlined(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ExcludeSemantics(
                              child: Icon(
                                icon,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              number(count),
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(label),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SectionTitle('Órdenes por estado'),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final entry in data.byState.entries)
              Chip(
                label: Text(
                  '${statusLabel(entry.key)}: ${number(entry.value)}',
                ),
              ),
          ],
        ),
        SectionTitle(
          'Últimas órdenes',
          trailing: TextButton(
            onPressed: () => onSelect(2),
            child: const Text('Ver todas'),
          ),
        ),
        if (data.orders.isEmpty)
          EmptyMessage(
            title: 'Todavía no hay órdenes',
            message: data.profile.isSeller
                ? 'Aquí verás las solicitudes que recibas.'
                : 'Conoce los productos y envía una solicitud cuando encuentres el indicado.',
            action: OutlinedButton(
              onPressed: () => onSelect(1),
              child: Text(
                data.profile.isSeller
                    ? 'Ver mis productos'
                    : 'Explorar productos',
              ),
            ),
          ),
        for (final order in data.orders)
          OrderRow(
            order: order,
            onTap: () => openProduct(
              context,
              repository,
              order.productId,
              onSessionExpired,
            ),
          ),
        const SectionTitle('Alertas de tus productos'),
        AlertsPanel(repository: repository, onSessionExpired: onSessionExpired),
      ],
    ),
  );
}

class AlertsPanel extends StatefulWidget {
  const AlertsPanel({
    super.key,
    required this.repository,
    required this.onSessionExpired,
  });
  final MarketplaceRepository repository;
  final VoidCallback onSessionExpired;
  @override
  State<AlertsPanel> createState() => _AlertsPanelState();
}

class _AlertsPanelState extends State<AlertsPanel> {
  late Future<AlertsData> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.repository.alerts();
  }

  void _refresh() => setState(() => _future = widget.repository.alerts());
  @override
  Widget build(BuildContext context) => FutureBuilder<AlertsData>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              LinearProgressIndicator(
                semanticsLabel: 'Consultando alertas climáticas',
              ),
              SizedBox(height: 12),
              Text('Consultando el clima de los orígenes relevantes…'),
            ],
          ),
        );
      }
      if (snapshot.hasError) {
        final error = snapshot.error;
        if (error is ApiException && error.statusCode == 401) {
          return Column(
            children: [
              const InfoNotice(
                'Tu sesión terminó. Inicia sesión para consultar las alertas.',
              ),
              TextButton(
                onPressed: widget.onSessionExpired,
                child: const Text('Volver al inicio de sesión'),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InfoNotice(
              'No pudimos consultar las alertas. El resto de tus datos está disponible.',
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar alertas'),
              ),
            ),
          ],
        );
      }
      final data = snapshot.requireData;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.alerts.isEmpty && data.notices.isEmpty)
            EmptyMessage(
              icon: Icons.wb_cloudy_outlined,
              title: 'Sin alertas para mostrar',
              message: widget.repository.isSeller
                  ? 'Las consultas de clima se relacionan con el origen de tus productos activos.'
                  : 'Aquí aparecerá el clima de productos que hayas visto o solicitado.',
            ),
          for (final notice in data.notices)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InfoNotice(notice),
            ),
          for (final alert in data.alerts)
            Card.outlined(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => openProduct(
                  context,
                  widget.repository,
                  alert.productId,
                  widget.onSessionExpired,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              alert.favourable
                                  ? Icons.wb_sunny_outlined
                                  : Icons.cloud_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              alert.productName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${alert.origin} · ${number(alert.temperature)} °C'),
                      const SizedBox(height: 12),
                      Text(alert.message),
                      const SizedBox(height: 12),
                      Text(
                        'Consultado ${date(alert.observed)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Fuente: Open-Meteo. Referencia climática para café; los precios no se modifican automáticamente.',
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar alertas'),
            ),
          ),
        ],
      );
    },
  );
}

class OrdersReadPage extends StatelessWidget {
  const OrdersReadPage({
    super.key,
    required this.repository,
    required this.onSessionExpired,
  });
  final MarketplaceRepository repository;
  final VoidCallback onSessionExpired;
  @override
  Widget build(BuildContext context) => RemoteView<List<OrderSummary>>(
    load: repository.orders,
    onSessionExpired: onSessionExpired,
    builder: (orders, reload) => PageBody(
      onRefresh: reload,
      children: [
        PageHeading(
          title: repository.isSeller ? 'Órdenes recibidas' : 'Mis órdenes',
          description:
              'Las últimas 20 solicitudes de esta cuenta y su estado actual.',
          onRefresh: reload,
        ),
        if (orders.isEmpty)
          const EmptyMessage(
            title: 'Aún no hay órdenes',
            message: 'Tus solicitudes aparecerán aquí.',
          ),
        for (final order in orders)
          OrderRow(
            order: order,
            onTap: () => openProduct(
              context,
              repository,
              order.productId,
              onSessionExpired,
            ),
          ),
      ],
    ),
  );
}
