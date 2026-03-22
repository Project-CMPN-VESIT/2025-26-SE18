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
  Map<String, dynamic>? _syncResult;

  Future<void> _syncFromSheet() async {
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
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$dateStr · ${auth.loginTime ?? ''}', style: TextStyle(color: Colors.blue[200]!.withValues(alpha: 0.8), fontSize: 14)),
                const SizedBox(height: 4),
                Text('Welcome, ${auth.user?['name'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
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
            const SizedBox(height: 16),
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
          // ─── Google Sheet Sync Card ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [const Color(0xFF10B981).withValues(alpha: 0.08), const Color(0xFF3B82F6).withValues(alpha: 0.08)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.cloud_sync, color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('User Directory Sync', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  Text('Import users from Google Sheet → Firebase', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                ])),
              ]),
              const SizedBox(height: 14),
              Text(
                'Add new teachers, coordinators, or admins in the NGO User Directory Google Sheet, then tap Sync to create their accounts automatically.',
                style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity, height: 44,
                child: ElevatedButton.icon(
                  onPressed: _syncing ? null : _syncFromSheet,
                  icon: _syncing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.sync, size: 18),
                  label: Text(_syncing ? 'Syncing...' : 'Sync from Google Sheet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              // ─── Sync Result Banner ───
              if (_syncResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_syncResult!['created'] ?? 0) > 0
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: (_syncResult!['created'] ?? 0) > 0 ? const Color(0xFF6EE7B7) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(
                        (_syncResult!['created'] ?? 0) > 0 ? Icons.check_circle : Icons.info_outline,
                        size: 16,
                        color: (_syncResult!['created'] ?? 0) > 0 ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _syncResult!['message']?.toString() ?? 'Sync complete',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      '✅ Created: ${_syncResult!['created'] ?? 0}  ·  ⏭ Skipped: ${_syncResult!['skipped'] ?? 0}',
                      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                    ),
                    if (_syncResult!['errors'] != null && (_syncResult!['errors'] as List).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '⚠ ${(_syncResult!['errors'] as List).join(', ')}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                      ),
                    ],
                  ]),
                ),
              ],
            ]),
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

  Widget _adminStat(String value, String label, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, color: Colors.blue[200], size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label.toUpperCase(), style: TextStyle(color: Colors.blue[200]!.withValues(alpha: 0.7), fontSize: 8, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}
