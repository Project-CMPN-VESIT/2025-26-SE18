import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../layouts/admin_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});
  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  String _filter = 'all';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tCount = data.teachers.length;
    final cCount = data.coordinators.length;
    final sCount = data.students.length;
    final aCount = tCount + cCount + sCount;

    String getTabLabel(String f) {
      if (f == 'teacher') return 'Teachers ($tCount)';
      if (f == 'coordinator') return 'Coordinators ($cCount)';
      if (f == 'student') return 'Students ($sCount)';
      return 'All ($aCount)';
    }

    List<Map<String, dynamic>> allUsers = [];
    if (_filter == 'all' || _filter == 'teacher') {
      allUsers.addAll(data.teachers.map((t) => {...t, 'role': 'teacher'}));
    }
    if (_filter == 'all' || _filter == 'coordinator') {
      allUsers.addAll(data.coordinators.map((c) => {...c, 'role': 'coordinator'}));
    }
    if (_filter == 'all' || _filter == 'student') {
      allUsers.addAll(data.students.map((s) => {...s, 'role': 'student'}));
    }
    if (_search.isNotEmpty) {
      allUsers = allUsers.where((u) => u['name'].toString().toLowerCase().contains(_search.toLowerCase())).toList();
    }

    return AdminLayout(
      child: Column(children: [
        const AppHeader(title: 'User Management', backTo: '/admin'),
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(hintText: 'Search users...', prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
            filled: true, fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
          ),
        )),
        // Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
            children: ['all', 'teacher', 'coordinator', 'student'].map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChipWidget(label: getTabLabel(f), active: _filter == f, onTap: () => setState(() => _filter = f)),
            )).toList(),
          )),
        ),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: allUsers.length,
          itemBuilder: (_, i) {
            final u = allUsers[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))),
              child: Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withValues(alpha: 0.1)),
                  child: Center(child: Text(u['name'][0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(u['name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  Text(u['email'] ?? u['roll'] ?? '', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  StatusBadge(label: u['role'], variant: u['role']),
                  const SizedBox(height: 4),
                  StatusBadge(label: u['status'], variant: u['status']),
                ]),
              ]),
            );
          },
        )),
      ]),
    );
  }
}
