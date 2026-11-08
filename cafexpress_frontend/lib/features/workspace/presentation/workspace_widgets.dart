import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../domain/marketplace_models.dart';

class RemoteView<T> extends StatefulWidget {
  const RemoteView({
    super.key,
    required this.load,
    required this.builder,
    required this.onSessionExpired,
  });
  final Future<T> Function() load;
  final Widget Function(T value, Future<void> Function() reload) builder;
  final VoidCallback onSessionExpired;
  @override
  State<RemoteView<T>> createState() => _RemoteViewState<T>();
}

class _RemoteViewState<T> extends State<RemoteView<T>> {
  late Future<T> _future;
  @override
  void initState() {
    super.initState();
    _future = Future.sync(widget.load);
  }

  Future<void> _reload() async {
    if (!mounted) return;
    final next = Future<T>.sync(widget.load);
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      /* FutureBuilder muestra el error. */
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Cargando datos'),
        );
      }
      if (snapshot.hasError) {
        final error = snapshot.error;
        final expired = error is ApiException && error.statusCode == 401;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: EmptyMessage(
                icon: expired ? Icons.lock_outline : Icons.cloud_off_outlined,
                title: expired
                    ? 'Tu sesión terminó'
                    : 'No pudimos cargar los datos',
                message: expired
                    ? 'Inicia sesión de nuevo para continuar.'
                    : (error is ApiException
                          ? error.message
                          : 'Revisa tu conexión e inténtalo otra vez.'),
                action: FilledButton(
                  onPressed: expired ? widget.onSessionExpired : _reload,
                  child: Text(
                    expired ? 'Volver al inicio de sesión' : 'Reintentar',
                  ),
                ),
              ),
            ),
          ),
        );
      }
      return widget.builder(snapshot.requireData, _reload);
    },
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.onRefresh});
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, bounds) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: bounds.maxWidth > 700 ? 40 : 20,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [...children, const SizedBox(height: 32)],
            ),
          ),
        ),
      ),
    );
    return onRefresh == null
        ? content
        : RefreshIndicator(onRefresh: onRefresh!, child: content);
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.title,
    required this.description,
    this.onRefresh,
  });
  final String title, description;
  final VoidCallback? onRefresh;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (onRefresh != null)
              IconButton(
                tooltip: 'Actualizar datos',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Icon(
            icon,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

class InfoNotice extends StatelessWidget {
  const InfoNotice(this.message, {super.key, this.isError = false});
  final String message;
  final bool isError;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isError
              ? colors.errorContainer
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isError ? colors.onErrorContainer : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class OrderRow extends StatelessWidget {
  const OrderRow({super.key, required this.order, required this.onTap});
  final OrderSummary order;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Card.outlined(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.productName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text('Cantidad: ${number(order.quantity)}'),
                  Text('Estado: ${statusLabel(order.state)}'),
                  Text(date(order.created)),
                  if (order.total != null)
                    Text('Total: ${number(order.total!)}'),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
