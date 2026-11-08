import 'dart:async';

import 'package:flutter/material.dart';

import '../../navigation/domain/user_role.dart';
import '../../navigation/presentation/main_navigation_shell.dart';
import '../data/marketplace_repository.dart';
import 'dashboard_page.dart';
import 'product_pages.dart';
import 'order_pages.dart';
import 'profile_page.dart';
import 'workspace_widgets.dart';
import '../data/climate_repository.dart';
import 'climate_controller.dart';
import 'climate_panel.dart';

class SessionWorkspace extends StatefulWidget {
  const SessionWorkspace({
    super.key,
    required this.repository,
    required this.onSignOut,
    this.climate,
  });
  final MarketplaceRepository repository;
  final VoidCallback onSignOut;
  final ClimateController? climate;
  @override
  State<SessionWorkspace> createState() => _SessionWorkspaceState();
}

class _SessionWorkspaceState extends State<SessionWorkspace> {
  int _index = 0;
  String? _name;
  late final ClimateController _climate;
  ClimateRepository? _weather;
  bool _modalScheduled = false, _showingModal = false;

  @override
  void initState() {
    super.initState();
    if (widget.climate case final existing?) {
      _climate = existing;
    } else {
      _weather = ClimateRepository(widget.repository);
      _climate = ClimateController(load: _weather!.fetch);
    }
    _climate.addListener(_scheduleModal);
    _climate.start();
  }

  void _scheduleModal() {
    if (_modalScheduled || _showingModal || !mounted) return;
    _modalScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _modalScheduled = false;
      if (!mounted ||
          _showingModal ||
          (_index != 0 && _index != 3) ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      final readings = _climate.unseen;
      if (readings.isEmpty) return;
      _showingModal = true;
      _climate.acknowledge(readings);
      unawaited(
        showDialog<bool>(
          context: context,
          builder: (_) => ClimateTrendDialog(readings: readings),
        ).then((viewClimate) {
          _showingModal = false;
          if (mounted && viewClimate == true) setState(() => _index = 3);
        }),
      );
    });
  }

  void _select(int index) {
    setState(() => _index = index);
    _scheduleModal();
  }

  @override
  void dispose() {
    _climate.removeListener(_scheduleModal);
    if (widget.climate == null) {
      _climate.dispose();
    } else {
      _climate.stop();
    }
    _weather?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClimateScope(
    controller: _climate,
    child: MainNavigationShell(
      userName: _name ?? widget.repository.session.name,
      initialRole: widget.repository.isSeller
          ? UserRole.vendedor
          : UserRole.comprador,
      initialIndex: _index,
      allowRolePreview: false,
      onDestinationChanged: _select,
      onSignOut: widget.onSignOut,
      sectionBuilder: (context, role, index, destination) => switch (index) {
        0 => DashboardPage(
          repository: widget.repository,
          onSessionExpired: widget.onSignOut,
          onSelect: _select,
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
            ClimatePanel(onSessionExpired: widget.onSignOut),
          ],
        ),
        _ => ProfilePage(
          repository: widget.repository,
          onSessionExpired: widget.onSignOut,
          onChanged: (profile) => setState(() => _name = profile.name),
        ),
      },
    ),
  );
}
