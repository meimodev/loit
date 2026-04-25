import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom-nav shell: Dashboard, Budgets, Reports, Settings.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.child});
  final Widget child;

  static const _tabs = <_Tab>[
    _Tab('/', Icons.dashboard_outlined, Icons.dashboard, 'Home'),
    _Tab('/rooms', Icons.group_outlined, Icons.group, 'Rooms'),
    _Tab('/budgets', Icons.savings_outlined, Icons.savings, 'Budgets'),
    _Tab('/reports', Icons.bar_chart_outlined, Icons.bar_chart, 'Reports'),
    _Tab('/settings', Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  int _indexFor(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].path ||
          (_tabs[i].path != '/' && location.startsWith(_tabs[i].path))) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _Tab {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _Tab(this.path, this.icon, this.selectedIcon, this.label);
}
