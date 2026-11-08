import 'package:flutter/material.dart';

import '../../navigation/domain/user_role.dart';
import '../../navigation/presentation/main_navigation_shell.dart';
import '../data/marketplace_repository.dart';
import 'dashboard_page.dart';
import 'product_pages.dart';
import 'profile_page.dart';
import 'workspace_widgets.dart';

class SessionWorkspace extends StatefulWidget {
  const SessionWorkspace({
    super.key,
    required this.repository,
    required this.onSignOut,
  });
  final MarketplaceRepository repository;
  final VoidCallback onSignOut;
  @override
  State<SessionWorkspace> createState() => _SessionWorkspaceState();
}

class _SessionWorkspaceState extends State<SessionWorkspace> {
  int _index = 0;
  String? _name;
  @override
  Widget build(BuildContext context) => MainNavigationShell(
    userName: _name ?? widget.repository.session.name,
    initialRole: widget.repository.isSeller
        ? UserRole.vendedor
        : UserRole.comprador,
    initialIndex: _index,
    allowRolePreview: false,
    onDestinationChanged: (index) => setState(() => _index = index),
    onSignOut: widget.onSignOut,
    sectionBuilder: (context, role, index, destination) => switch (index) {
      0 => DashboardPage(
        repository: widget.repository,
        onSessionExpired: widget.onSignOut,
        onSelect: (index) => setState(() => _index = index),
      ),
      1 => ProductListPage(
        repository: widget.repository,
        onSessionExpired: widget.onSignOut,
      ),
      2 => OrdersReadPage(
        repository: widget.repository,
        onSessionExpired: widget.onSignOut,
      ),
      3 => PageBody(
        children: [
          const PageHeading(
            title: 'Clima de tus productos',
            description: 'Consulta las condiciones de los orígenes relacionados con tu cuenta.',
          ),
          AlertsPanel(
            repository: widget.repository,
            onSessionExpired: widget.onSignOut,
          ),
        ],
      ),
      _ => ProfilePage(
        repository: widget.repository,
        onSessionExpired: widget.onSignOut,
        onChanged: (profile) => setState(() => _name = profile.name),
      ),
    },
  );
}
