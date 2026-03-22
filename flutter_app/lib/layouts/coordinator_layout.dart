import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_widgets.dart';

class CoordinatorLayout extends StatelessWidget {
  final Widget child;
  const CoordinatorLayout({super.key, required this.child});

  static const _navItems = [
    NavItem(path: '/coordinator', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Home'),
    NavItem(path: '/coordinator/manage', icon: Icons.manage_accounts_outlined, activeIcon: Icons.manage_accounts, label: 'Staff'),
    NavItem(path: '/coordinator/analytics', icon: Icons.analytics_outlined, activeIcon: Icons.analytics, label: 'Analytics'),
    NavItem(path: '/coordinator/leaves', icon: Icons.event_busy_outlined, activeIcon: Icons.event_busy, label: 'Leaves'),
    NavItem(path: '/coordinator/centres', icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Centres'),
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
