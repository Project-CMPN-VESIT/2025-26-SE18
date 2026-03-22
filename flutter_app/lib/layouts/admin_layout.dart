import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_widgets.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  const AdminLayout({super.key, required this.child});

  static const _navItems = [
    NavItem(path: '/admin', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Home'),
    NavItem(path: '/admin/users', icon: Icons.group_outlined, activeIcon: Icons.group, label: 'Users'),
    NavItem(path: '/admin/zones', icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Zones'),
    NavItem(path: '/admin/leaves', icon: Icons.event_busy_outlined, activeIcon: Icons.event_busy, label: 'Leaves'),
    NavItem(path: '/admin/analytics', icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Analytics'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return PageShell(
      child: Scaffold(
        body: child,
        bottomNavigationBar: AppBottomNav(items: _navItems, activePath: location),
      ),
    );
  }
}
