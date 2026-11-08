import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../domain/climate_trend.dart';
import '../domain/marketplace_models.dart';
import 'climate_controller.dart';
import 'workspace_widgets.dart';

class ClimatePanel extends StatelessWidget {
  const ClimatePanel({super.key, required this.onSessionExpired});
  final VoidCallback onSessionExpired;
  @override
  Widget build(BuildContext context) {
    final climate = ClimateScope.maybeOf(context);
    if (climate == null) return const SizedBox.shrink();
    final error = climate.error;
    final expired = error is ApiException && error.statusCode == 401;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Consulta automática cada ${number(climate.interval.inMinutes)}${climate.interval.inMinutes == 1 ? ' minuto' : ' minutos'} mientras la aplicación esté abierta.',
        ),
        const SizedBox(height: 12),
        if (climate.loading) ...[
          const LinearProgressIndicator(semanticsLabel: 'Consultando clima'),
          const SizedBox(height: 12),
        ],
        if (error != null) ...[
          InfoNotice(
            expired ? 'Tu sesión terminó. Vuelve a iniciar sesión.' : 'No pudimos actualizar el clima. Puedes reintentar; las demás funciones siguen disponibles.',
          ),
          if (expired)
            TextButton(
              onPressed: onSessionExpired,
              child: const Text('Volver al inicio de sesión'),
            ),
        ],
        if (climate.updated case final updated?)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Última consulta: ${date(updated)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (!climate.loading &&
            error == null &&
            climate.data.readings.isEmpty &&
            climate.data.notices.isEmpty)
          const EmptyMessage(
            icon: Icons.wb_cloudy_outlined,
            title: 'Sin productos para consultar',
            message: 'El clima se relaciona con tus productos activos o con los productos que hayas visto o solicitado.',
          ),
        for (final notice in climate.data.notices)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InfoNotice(notice),
          ),
        for (final reading in climate.data.readings)
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          reading.falling
                              ? Icons.trending_down
                              : Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reading.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(reading.origin),
                  const SizedBox(height: 8),
                  Text(
                    reading.products.map((product) => product.name).join(' · '),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${number(reading.temperature)} °C actuales · ${number(reading.rain)} mm de lluvia prevista hoy',
                  ),
                  Text(
                    'Temperatura media prevista: ${number(reading.meanTemperature)} °C',
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          'Estimación según el clima, no precios de mercado. Regla general: temperatura de 18 a 24 °C y lluvia diaria de 2 a 10 mm favorecen una tendencia a la baja; fuera de esos rangos, al alza.',
        ),
        const SizedBox(height: 8),
        const Text(
          'Fuente: Open-Meteo. La consulta no modifica el precio de tus productos.',
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: climate.loading || expired ? null : climate.refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar clima'),
          ),
        ),
      ],
    );
  }
}

class ClimateTrendDialog extends StatelessWidget {
  const ClimateTrendDialog({super.key, required this.readings});
  final List<ClimateReading> readings;
  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const Key('climate-trend-dialog'),
    scrollable: true,
    icon: const Icon(Icons.insights_outlined),
    title: const Text('Tendencia de precios'),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final reading in readings)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      reading.falling ? Icons.trending_down : Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reading.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(reading.origin),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Text(
            'Estimación por las condiciones del clima. Los precios publicados se mantienen.',
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Ver clima'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Entendido'),
      ),
    ],
  );
}
