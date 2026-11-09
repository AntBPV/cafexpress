import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'package:cafexpress_frontend/features/orders/screens/order_generation_screen.dart';
import '../domain/user_role.dart';

/// Especificación de cada destino dentro de la interfaz inicial de navegación (F2-34).
class NavigationDestinationSpec {
  const NavigationDestinationSpec({
    required this.keyName,
    required this.label,
    required this.title,
    required this.description,
    required this.icon,
    required this.selectedIcon,
  });

  final String keyName;
  final String label;
  final String title;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
}

/// F2-34: Interfaz inicial de navegación adaptable por rol (Comprador / Vendedor).
///
/// Actúa como contenedor base (Shell) donde cada módulo del equipo (Dashboard,
/// Catálogo/Productos, Órdenes, Clima y Perfiles) puede inyectar su vista.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({
    super.key,
    this.userName,
    this.initialRole = UserRole.comprador,
    this.initialIndex = 0,
    this.allowRolePreview = true,
    this.onSignOut,
    this.sectionBuilder,
    this.onDestinationChanged,
  });

  final String? userName;
  final UserRole initialRole;
  final int initialIndex;
  final bool allowRolePreview;
  final ValueChanged<int>? onDestinationChanged;
  final VoidCallback? onSignOut;

  /// Permite que los demás módulos inyecten su pantalla según el rol e índice activo.
  final Widget Function(
    BuildContext context,
    UserRole role,
    int index,
    NavigationDestinationSpec destination,
  )?
  sectionBuilder;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late UserRole _role;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
    _selectedIndex = widget.initialIndex.clamp(0, 4);
  }

  List<NavigationDestinationSpec> get _destinations {
    if (_role == UserRole.vendedor) {
      return const [
        NavigationDestinationSpec(
          keyName: 'nav-tab-inicio',
          label: 'Inicio',
          title: 'Resumen del Vendedor',
          description: 'Espacio de navegación reservado para el Dashboard del vendedor (productos publicados, órdenes activas y alertas recientes).',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
        ),
        NavigationDestinationSpec(
          keyName: 'nav-tab-productos',
          label: 'Mis Lotes',
          title: 'Publicación y Gestión de Productos',
          description: 'Espacio de navegación reservado para publicar lotes de café/cacao y editar precios manualmente.',
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2_rounded,
        ),
        NavigationDestinationSpec(
          keyName: 'nav-tab-ordenes',
          label: 'Órdenes',
          title: 'Órdenes Recibidas',
          description: 'Espacio de navegación reservado para listar las órdenes recibidas y avanzar su estado en el historial.',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
        ),
        NavigationDestinationSpec(
          keyName: 'nav-tab-clima',
          label: 'Clima',
          title: 'Clima y Alertas de Región',
          description: 'Espacio de navegación reservado para consultar alertas climáticas por umbral en la región productora.',
          icon: Icons.thunderstorm_outlined,
          selectedIcon: Icons.thunderstorm_rounded,
        ),
        NavigationDestinationSpec(
          keyName: 'nav-tab-perfil',
          label: 'Perfil',
          title: 'Perfil del Vendedor',
          description: 'Espacio de navegación reservado para el módulo de perfiles de vendedor.',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      ];
    }

    return const [
      NavigationDestinationSpec(
        keyName: 'nav-tab-inicio',
        label: 'Inicio',
        title: 'Resumen del Comprador',
        description: 'Espacio de navegación reservado para el Dashboard del comprador (órdenes activas y alertas relevantes).',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
      ),
      NavigationDestinationSpec(
        keyName: 'nav-tab-catalogo',
        label: 'Catálogo',
        title: 'Catálogo de Café y Cacao',
        description: 'Espacio de navegación reservado para explorar el catálogo de productos, filtros y detalle del lote.',
        icon: Icons.storefront_outlined,
        selectedIcon: Icons.storefront_rounded,
      ),
      NavigationDestinationSpec(
        keyName: 'nav-tab-ordenes',
        label: 'Órdenes',
        title: 'Mis Órdenes y Seguimiento',
        description: 'Espacio de navegación reservado para la generación y trazabilidad de órdenes de compra.',
        icon: Icons.local_shipping_outlined,
        selectedIcon: Icons.local_shipping_rounded,
      ),
      NavigationDestinationSpec(
        keyName: 'nav-tab-clima',
        label: 'Clima',
        title: 'Alertas Climáticas de Compra',
        description: 'Espacio de navegación reservado para alertas de buen momento de compra según el clima de origen.',
        icon: Icons.wb_sunny_outlined,
        selectedIcon: Icons.wb_sunny_rounded,
      ),
      NavigationDestinationSpec(
        keyName: 'nav-tab-perfil',
        label: 'Perfil',
        title: 'Mi Perfil Individual',
        description: 'Espacio de navegación reservado para la interfaz frontend de visualización de perfil individual.',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
      ),
    ];
  }

  void _updateRole(UserRole newRole) {
    if (_role == newRole) return;
    setState(() => _role = newRole);
  }

  void _toggleRole() {
    _updateRole(
      _role == UserRole.comprador ? UserRole.vendedor : UserRole.comprador,
    );
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
    widget.onDestinationChanged?.call(index);
  }

  @override
  void didUpdateWidget(covariant MainNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _selectedIndex = widget.initialIndex.clamp(0, 4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final destinations = _destinations;
    final activeSpec = destinations[_selectedIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 840;
        final bodyContent =
            widget.sectionBuilder?.call(
              context,
              _role,
              _selectedIndex,
              activeSpec,
            ) ??
            _NavigationSectionContainer(
              userName: widget.userName,
              role: _role,
              selectedIndex: _selectedIndex,
              destinations: destinations,
              onSelectTab: _selectTab,
              onRoleChanged: widget.allowRolePreview ? _updateRole : null,
              onSignOut: widget.onSignOut,
            );

        return Scaffold(
          appBar: AppBar(
            backgroundColor: colors.surface,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 16,
            title: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.eco_outlined,
                    color: colors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Caféxpress',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              if (widget.allowRolePreview)
                TextButton.icon(
                  key: const Key('nav-role-switch'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: _toggleRole,
                  icon: Icon(_role.icon, size: 18),
                  label: Text('Rol: ${_role.label}'),
                )
              else
                Center(child: Text(_role.label)),
              if (widget.onSignOut != null)
                IconButton(
                  key: const Key('nav-logout'),
                  tooltip: 'Cerrar sesión',
                  onPressed: widget.onSignOut,
                  icon: const Icon(Icons.logout_rounded),
                ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: colors.outlineVariant),
            ),
          ),
          body: SafeArea(
            child: useRail
                ? Row(
                    children: [
                      NavigationRail(
                        key: const Key('main-navigation-rail'),
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: _selectTab,
                        labelType: NavigationRailLabelType.all,
                        backgroundColor: colors.surface,
                        destinations: [
                          for (final item in destinations)
                            NavigationRailDestination(
                              icon: Icon(item.icon),
                              selectedIcon: Icon(item.selectedIcon),
                              label: Text(item.label, key: Key(item.keyName)),
                            ),
                        ],
                      ),
                      VerticalDivider(width: 1, color: colors.outlineVariant),
                      Expanded(child: bodyContent),
                    ],
                  )
                : bodyContent,
          ),
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  key: const Key('main-bottom-navigation'),
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectTab,
                  destinations: [
                    for (final item in destinations)
                      NavigationDestination(
                        key: Key(item.keyName),
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: item.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

/// Contenedor base de sección para la estructura inicial de navegación (F2-34).
class _NavigationSectionContainer extends StatelessWidget {
  const _NavigationSectionContainer({
    required this.userName,
    required this.role,
    required this.selectedIndex,
    required this.destinations,
    required this.onSelectTab,
    required this.onRoleChanged,
    this.onSignOut,
  });

  final String? userName;
  final UserRole role;
  final int selectedIndex;
  final List<NavigationDestinationSpec> destinations;
  final ValueChanged<int> onSelectTab;
  final ValueChanged<UserRole>? onRoleChanged;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final active = destinations[selectedIndex];
    final cleanUser = userName?.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.coffee,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Navegación activa · Vista ${role.label}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      header: true,
                      child: Text(
                        active.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.cream,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (cleanUser != null && cleanUser.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Sesión: $cleanUser',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.cream,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            active.selectedIcon,
                            color: colors.onPrimaryContainer,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sección: ${active.label}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rol actual: ${role.label} (${role.subtitle})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(active.description, style: theme.textTheme.bodyLarge),
                  
                    // =======================================================
                    // BOTÓN DE PRUEBA CON LAS DOS CONDICIONES APLICADAS
                    // =======================================================
                    if (selectedIndex == 0 && role == UserRole.comprador) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
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
                    ],
                    // =======================================================

                    if (onRoleChanged case final changeRole?) ...[
                      const SizedBox(height: 20),
                      Divider(color: colors.outlineVariant),
                      const SizedBox(height: 16),
                      Text(
                        'Cambiar rol de navegación:',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final itemRole in UserRole.values)
                            itemRole == role
                                ? FilledButton.icon(
                                    key: Key(
                                      'nav-role-option-${itemRole.name}',
                                    ),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(150, 48),
                                    ),
                                    onPressed: () => changeRole(itemRole),
                                    icon: Icon(itemRole.icon),
                                    label: Text(itemRole.label),
                                  )
                                : OutlinedButton.icon(
                                    key: Key(
                                      'nav-role-option-${itemRole.name}',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(150, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () => changeRole(itemRole),
                                    icon: Icon(itemRole.icon),
                                    label: Text(itemRole.label),
                                  ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accesos rápidos de la barra de navegación',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < destinations.length; i++)
                          ActionChip(
                            avatar: Icon(destinations[i].icon, size: 18),
                            label: Text(destinations[i].label),
                            onPressed: () => onSelectTab(i),
                          ),
                      ],
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
} 