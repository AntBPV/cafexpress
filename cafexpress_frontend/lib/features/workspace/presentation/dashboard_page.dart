import 'package:flutter/material.dart';

import '../data/marketplace_repository.dart';
import '../domain/marketplace_models.dart';
import 'package:cafexpress_frontend/features/orders/screens/order_generation_screen.dart';
import 'order_pages.dart';
import 'workspace_widgets.dart';
import 'climate_panel.dart';

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
            onTap: () async {
              await openOrder(context, repository, order.id, onSessionExpired);
              if (context.mounted) await reload();
            },
          ),

        Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Probar Generación de Orden'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderGenerationScreen(),
                ),
              );
            },
          ),
        ),
        
        const SectionTitle('Clima y tendencia de precios'),
        ClimatePanel(onSessionExpired: onSessionExpired),
      ],
    ),
  );
} 