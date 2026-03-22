import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_widgets.dart';

class TeacherLayout extends StatelessWidget {
  final Widget child;
  const TeacherLayout({super.key, required this.child});

  static const _navItems = [
    NavItem(path: '/teacher', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Home'),
    NavItem(path: '/teacher/attendance', icon: Icons.event_available_outlined, activeIcon: Icons.event_available, label: 'Attendance'),
    NavItem(path: '/teacher/diary', icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: 'Diary'),
    NavItem(path: '/teacher/students', icon: Icons.group_outlined, activeIcon: Icons.group, label: 'Students'),
    NavItem(path: '/teacher/exams', icon: Icons.school_outlined, activeIcon: Icons.school, label: 'Exams'),
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
