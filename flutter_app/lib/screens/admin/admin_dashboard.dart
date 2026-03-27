import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../layouts/admin_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _syncing = false;
  bool _syncingStudents = false;
  Map<String, dynamic>? _syncResult;
  Map<String, dynamic>? _studentSyncResult;

  Future<void> _syncUsersFromSheet() async {
    setState(() { _syncing = true; _syncResult = null; });
    try {
      final result = await context.read<DataProvider>().syncUsersFromSheet();
      if (mounted) setState(() { _syncing = false; _syncResult = result; });
    } catch (e) {
      if (mounted) {
        setState(() { _syncing = false; _syncResult = {'message': 'Error: $e'}; });
      }
    }
  }

  Future<void> _syncStudentsFromSheet() async {
    setState(() { _syncingStudents = true; _studentSyncResult = null; });
    try {
      final result = await context.read<DataProvider>().syncStudentsFromSheet();
      if (mounted) setState(() { _syncingStudents = false; _studentSyncResult = result; });
    } catch (e) {
      if (mounted) {
        setState(() { _syncingStudents = false; _studentSyncResult = {'message': 'Error: $e'}; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final data = context.watch<DataProvider>();
    final dateStr = DateFormat('MMM d, yyyy').format(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AdminLayout(
      child: Column(children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0F1B3E), AppTheme.primary])),
          padding: const EdgeInsets.fromLTRB(20, 36, 20, 16),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$dateStr · ${auth.loginTime ?? ''}', style: TextStyle(color: Colors.blue[200]!.withValues(alpha: 0.8), fontSize: 14)),
                const SizedBox(height: 4),
                Text('Welcome, ${auth.user?['name'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF34D399))),
                    const SizedBox(width: 4),
                    const Text('System Online', style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 10, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ]),
              GestureDetector(
                onTap: () => auth.logout(),
                child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)), child: const Icon(Icons.logout, color: Colors.white, size: 20)),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _adminStat('${data.zones.length}', 'Zones', Icons.map),
              const SizedBox(width: 8),
              _adminStat('${data.centres.length}', 'Centres', Icons.location_city),
              const SizedBox(width: 8),
              _adminStat('${data.teachers.length}', 'Teachers', Icons.person),
            ]),
          ]),
        ),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ─── Google Sheet Sync Cards ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Sync Card
              Expanded(
                child: _syncCard(
                  title: 'Staff Sync',
                  subtitle: 'Users directory',
                  description: 'Sync NGO User Directory sheet to Firebase Auth.',
                  icon: Icons.person_pin_rounded,
                  color: const Color(0xFF10B981),
                  syncing: _syncing,
                  onSync: _syncUsersFromSheet,
                  result: _syncResult,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              // Student Sync Card
              Expanded(
                child: _syncCard(
                  title: 'Student Sync',
                  subtitle: 'Student records',
                  description: 'Update student data from zonal Google Sheets.',
                  icon: Icons.school_rounded,
                  color: const Color(0xFF3B82F6),
                  syncing: _syncingStudents,
                  onSync: _syncStudentsFromSheet,
                  result: _studentSyncResult,
                  isDark: isDark,
                  isStudent: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text('Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          const SizedBox(height: 12),
          GridView.count(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.1, children: const [
            ActionCard(to: '/admin/users', icon: Icons.group, title: 'User Management', subtitle: 'All Staff', iconColor: Color(0xFF8B5CF6)),
            ActionCard(to: '/admin/zones', icon: Icons.map, title: 'Zones & Centres', subtitle: 'Global Network', iconColor: Color(0xFF3B82F6)),
            ActionCard(to: '/admin/leaves', icon: Icons.event_busy, title: 'Leave Management', subtitle: 'Staff Oversight', iconColor: Color(0xFFF59E0B)),
            ActionCard(to: '/admin/analytics', icon: Icons.analytics, title: 'Global Analytics', subtitle: 'Performance Reports', iconColor: Color(0xFF14B8A6)),
          ]),
          const SizedBox(height: 24),
          Row(children: [
            const Icon(Icons.bolt, color: Color(0xFFF59E0B), size: 18),
            const SizedBox(width: 8),
            Text('ADMIN SHORTCUTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569), letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 12),
          const ShortcutLink(to: '/admin/add-coordinator', icon: Icons.person_add, title: 'Add New Coordinator', subtitle: 'Onboarding portal'),
          const SizedBox(height: 12),
          const ShortcutLink(to: '/admin/add-teacher', icon: Icons.school, title: 'Add New Teacher', subtitle: 'Staff recruitment'),
          const SizedBox(height: 100),
        ]))),
      ]),
    );
  }

  Widget _syncCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required bool syncing,
    required VoidCallback onSync,
    required Map<String, dynamic>? result,
    required bool isDark,
    bool isStudent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
              Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
            ])),
          ]),
          const SizedBox(height: 12),
          Text(description, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.4)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 38,
            child: ElevatedButton(
              onPressed: syncing ? null : onSync,
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: syncing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Sync Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (isStudent) ...[
                  Text('Centres: ${result['syncedCentres'] ?? 0}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                  Text('Students: ${result['syncedStudents'] ?? 0}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                ] else ...[
                  Text('Created: ${result['created'] ?? 0}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                  Text('Skipped: ${result['skipped'] ?? 0}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                ],
                if (result['message'] != null)
                   Padding(
                     padding: const EdgeInsets.only(top: 4),
                     child: Text(result['message'], style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                   ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _adminStat(String value, String label, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, color: Colors.blue[200], size: 18),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label.toUpperCase(), style: TextStyle(color: Colors.blue[200]!.withValues(alpha: 0.7), fontSize: 8, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}
