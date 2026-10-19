import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Composición compartida por el acceso y el registro, con desplazamiento nativo.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.showBackButton = false,
  });

  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: showBackButton
        ? AppBar(leading: const BackButton(), title: const Text('Caféxpress'))
        : null,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final expanded =
              constraints.maxWidth >= 900 && constraints.maxHeight >= 500;
          final content = _buildContent(context, expanded: expanded);
          if (!expanded) return content;
          return Row(
            children: [
              const Expanded(flex: 5, child: _BrandPanel()),
              Expanded(flex: 6, child: content),
            ],
          );
        },
      ),
    ),
  );

  Widget _buildContent(BuildContext context, {required bool expanded}) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.symmetric(
          horizontal: expanded ? 48 : 24,
          vertical: expanded ? 48 : 32,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - (expanded ? 96 : 64)).clamp(
              0,
              double.infinity,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!expanded && !showBackButton) ...[
                    const _Wordmark(),
                    const SizedBox(height: 56),
                  ],
                  child,
                  const SizedBox(height: 48),
                  Divider(color: colors.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'De la preparación al destino, todo bajo control.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.eco_outlined,
            size: 36,
            color: onDark ? AppColors.gold : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            'Caféxpress',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: onDark ? AppColors.cream : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.coffee,
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Wordmark(onDark: true),
                  const SizedBox(height: 64),
                  const Spacer(),
                  Text(
                    'Café y cacao,',
                    style: Theme.of(context).textTheme.headlineLarge
                        ?.copyWith(color: AppColors.gold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'conectados con nuevos mercados.',
                    style: Theme.of(context).textTheme.headlineLarge
                        ?.copyWith(color: AppColors.cream),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Compra y vende tu producto desde un solo lugar.',
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: AppColors.cream),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
