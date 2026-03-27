import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../layouts/coordinator_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';

class ManageStaff extends StatefulWidget {
  const ManageStaff({super.key});
  @override
  State<ManageStaff> createState() => _ManageStaffState();
}

class _ManageStaffState extends State<ManageStaff> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _search = '';
  String _selectedCentre = 'All';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build unique centre list for filter
    final centreNames = <String>{'All'};
    for (var t in data.teachers) {
      if (t['centre'] != null) centreNames.add(t['centre']);
    }
    for (var s in data.students) {
      if (s['centre'] != null) centreNames.add(s['centre']);
    }

    var teachers = data.teachers.where((t) => t['name'].toString().toLowerCase().contains(_search.toLowerCase())).toList();
    var students = data.students.where((s) => s['name'].toString().toLowerCase().contains(_search.toLowerCase())).toList();

    if (_selectedCentre != 'All') {
      teachers = teachers.where((t) => t['centre'] == _selectedCentre).toList();
      students = students.where((s) => s['centre'] == _selectedCentre).toList();
    }

    return CoordinatorLayout(
      child: Column(children: [
        AppHeader(title: 'Manage Staff', backTo: '/coordinator', rightActions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add, color: AppTheme.primary),
            onSelected: (v) => context.go(v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: '/coordinator/manage/add-student', child: Text('Add Student')),
            ],
          ),
        ]),
        Container(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: TabBar(controller: _tabCtrl, labelColor: AppTheme.primary, unselectedLabelColor: const Color(0xFF94A3B8), indicatorColor: AppTheme.primary, tabs: const [Tab(text: 'Teachers'), Tab(text: 'Students')]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCentre,
                isExpanded: true,
                icon: Icon(Icons.filter_list, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                items: centreNames.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCentre = v ?? 'All'),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(hintText: 'Search...', prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
              filled: true, fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(controller: _tabCtrl, children: [
            _buildList(teachers, isDark, isTeacher: true),
            _buildList(students, isDark, isTeacher: false),
          ]),
        ),
      ]),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, bool isDark, {required bool isTeacher}) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        return GestureDetector(
          onTap: () => _showDetails(context, item, isTeacher, Provider.of<DataProvider>(context, listen: false).leaves),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
            ),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withValues(alpha: 0.1)),
                child: Center(child: Text(item['name'][0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                Text(isTeacher ? '${item['centre']}' : '${item['roll']} · ${item['class']}', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
              ])),
              StatusBadge(label: item['status'], variant: item['status']),
            ]),
          ),
        );
      },
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> item, bool isTeacher, List<Map<String,dynamic>> leaves) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // For teachers, prep leave data
    final teacherLeaves = isTeacher ? leaves.where((l) => l['userId'] == item['id'] || l['userName'] == item['name']).toList() : [];
    final approved = teacherLeaves.where((l) => l['status'] == 'approved').length;
    final rejected = teacherLeaves.where((l) => l['status'] == 'rejected' || l['status'] == 'denied').length;
    final total = teacherLeaves.length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withValues(alpha: 0.1)),
                  child: Center(child: Text(item['name'][0], style: const TextStyle(color: AppTheme.primary, fontSize: 24, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['name'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  StatusBadge(label: isTeacher ? 'Teacher' : 'Student', variant: isTeacher ? 'teacher' : 'student'),
                ])),
              ],
            ),
            const SizedBox(height: 24),
            if (isTeacher) ...[
              _detailRow(Icons.location_on, 'Centre', item['centre'] ?? 'N/A', isDark),
              _detailRow(Icons.phone, 'Phone', item['phone'] ?? 'N/A', isDark),
              _detailRow(Icons.email, 'Email', item['email'] ?? 'N/A', isDark),
              const SizedBox(height: 24),
              Text('Leave History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _leaveStat('Total', total.toString(), Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: _leaveStat('Approved', approved.toString(), Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _leaveStat('Rejected', rejected.toString(), Colors.red)),
                ],
              ),
            ] else ...[
              _detailRow(Icons.numbers, 'Roll No', item['roll'] ?? 'N/A', isDark),
              _detailRow(Icons.school, 'Class', item['class'] ?? 'N/A', isDark),
              _detailRow(Icons.location_on, 'Centre', item['centre'] ?? 'N/A', isDark),
              const SizedBox(height: 24),
              Text('Attendance History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _leaveStat('Attended', (item['presentCount'] ?? 0).toString(), Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _leaveStat('Missed', (item['absentCount'] ?? 0).toString(), Colors.red)),
                ],
              ),
              if (item['presentCount'] == null) ...[
                const SizedBox(height: 12),
                Center(child: Text('Note: Tap "Sync" on dashboard to update attendance stats.', style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontStyle: FontStyle.italic))),
              ],
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String val, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Text('$label:', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(child: Text(val, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _leaveStat(String label, String val, Color c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
