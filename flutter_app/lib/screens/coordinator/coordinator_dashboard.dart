import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/data_provider.dart';
import '../../layouts/coordinator_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class CoordinatorDashboard extends StatelessWidget {
  const CoordinatorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final data = context.watch<DataProvider>();
    final dateStr = DateFormat('MMM d, yyyy').format(DateTime.now());
    final pendingLeaves = data.leaves.where((l) => l['status'] == 'pending').length;

    return CoordinatorLayout(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.primary, AppTheme.primaryDark])),
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$dateStr · ${auth.loginTime ?? ''}', style: TextStyle(color: Colors.blue[200], fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Welcome, ${auth.user?['name'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ]),
                    Row(children: [
                      _circleBtn(theme.isDark ? Icons.light_mode : Icons.dark_mode, () => theme.toggleTheme()),
                      const SizedBox(width: 8),
                      _circleBtn(Icons.logout, () => auth.logout()),
                    ]),
                  ],
                ),
                const SizedBox(height: 16),
                Row(children: [
                  _miniStat('${data.centres.length}', 'Centres'),
                  const SizedBox(width: 8),
                  _miniStat('${data.teachers.length}', 'Teachers'),
                  const SizedBox(width: 8),
                  _miniStat('${data.students.length}', 'Students'),
                ]),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B))),
                const SizedBox(height: 12),
                GridView.count(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.25, children: [
                  const ActionCard(to: '/coordinator/manage', icon: Icons.manage_accounts, title: 'Manage Staff', subtitle: 'Teachers & Students', iconColor: Color(0xFF8B5CF6)),
                  const ActionCard(to: '/coordinator/centres', icon: Icons.map, title: 'Centres', subtitle: 'Your Region', iconColor: Color(0xFF3B82F6)),
                  const ActionCard(to: '/coordinator/analytics', icon: Icons.analytics, title: 'Analytics', subtitle: 'Performance Data', iconColor: Color(0xFF14B8A6)),
                  ActionCard(to: '/coordinator/leaves', icon: Icons.event_busy, title: 'Leave Approvals', subtitle: 'Pending Requests', iconColor: const Color(0xFFF59E0B), badgeCount: pendingLeaves),
                ]),
                if (pendingLeaves > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFDE68A))),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.warning, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('$pendingLeaves Pending Approval${pendingLeaves > 1 ? 's' : ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                        const SizedBox(height: 2),
                        const Text('Teachers awaiting leave approval', style: TextStyle(fontSize: 12, color: Color(0xFFD97706))),
                        const SizedBox(height: 8),
                        GestureDetector(onTap: () => context.go('/coordinator/leaves'), child: const Text('Review Now →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary))),
                      ])),
                    ]),
                  ),
                ],
                const SizedBox(height: 16),
                ShortcutLink(to: '/coordinator/reports', icon: Icons.summarize, title: 'Monthly Reports', subtitle: 'View & Export'),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)), child: Icon(icon, color: Colors.white, size: 20)),
  );

  Widget _miniStat(String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label.toUpperCase(), style: TextStyle(color: Colors.blue[200], fontSize: 9, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}
