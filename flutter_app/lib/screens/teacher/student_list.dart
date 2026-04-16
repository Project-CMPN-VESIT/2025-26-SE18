import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../layouts/teacher_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';

class StudentList extends StatefulWidget {
  const StudentList({super.key});

  @override
  State<StudentList> createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  String _search = '';
  String _filterZone = 'All';
  String _filterCentre = 'All';
  List<Map<String, dynamic>> _sheetStudents = [];
  bool _loadingSheet = true;
  String? _sheetError;

  @override
  void initState() {
    super.initState();
    _fetchFromCloud();
  }

  Future<void> _fetchFromCloud() async {
    setState(() { _loadingSheet = true; _sheetError = null; });
    try {
      final auth = context.read<AppAuthProvider>();
      final dp = context.read<DataProvider>();
      final students = await dp.fetchStudentsByLocation(
        zone: auth.user?['zone'],
        centre: auth.user?['centre'],
      );
      if (mounted) {
        setState(() { _sheetStudents = students; _loadingSheet = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _sheetError = e.toString(); _loadingSheet = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Also listen to Firestore students as fallback
    final firestoreStudents = context.watch<DataProvider>().students;
    // Use sheet data if available, fallback to Firestore
    final students = _sheetStudents.isNotEmpty ? _sheetStudents : firestoreStudents;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Extract unique zones and centres from the data
    final zones = ['All', ...{...students.map((s) => s['zone']?.toString() ?? '').where((z) => z.isNotEmpty)}];
    final centres = ['All', ...{...students.map((s) => s['centre']?.toString() ?? '').where((c) => c.isNotEmpty)}];

    // Apply filters
    var filtered = students.where((s) {
      final matchesSearch = s['name'].toString().toLowerCase().contains(_search.toLowerCase()) ||
          s['roll'].toString().toLowerCase().contains(_search.toLowerCase());
      final matchesZone = _filterZone == 'All' || s['zone'] == _filterZone;
      final matchesCentre = _filterCentre == 'All' || s['centre'] == _filterCentre;
      return matchesSearch && matchesZone && matchesCentre;
    }).toList();

    return TeacherLayout(
      child: Column(
        children: [
          AppHeader(
            title: 'Students (${filtered.length})',
            backTo: '/teacher',
            rightActions: [
              // Refresh from Sheet
              IconButton(
                icon: _loadingSheet
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                    : const Icon(Icons.cloud_download, color: AppTheme.primary),
                onPressed: _loadingSheet ? null : _fetchFromCloud,
                tooltip: 'Refresh from Cloud',
              ),
              IconButton(
                icon: const Icon(Icons.person_add, color: AppTheme.primary),
                onPressed: () => context.go('/teacher/students/add'),
              ),
            ],
          ),

          // Source indicator
          if (_sheetStudents.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text('Data from Cloud Storage', style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          if (_sheetError != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Using Firestore (Sheet error)', style: TextStyle(fontSize: 11, color: Colors.red[400])),
            ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
              ),
            ),
          ),

          // Filters row
          if (context.read<AppAuthProvider>().role != 'teacher')
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                children: [
                  Expanded(child: _buildFilterDropdown(
                    icon: Icons.map_outlined,
                    label: 'Zone',
                    value: _filterZone,
                    items: zones,
                    onChanged: (v) => setState(() { _filterZone = v!; }),
                    isDark: isDark,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _buildFilterDropdown(
                    icon: Icons.location_on_outlined,
                    label: 'Centre',
                    value: _filterCentre,
                    items: centres,
                    onChanged: (v) => setState(() { _filterCentre = v!; }),
                    isDark: isDark,
                  )),
                ],
              ),
            ),

          Expanded(
            child: _loadingSheet
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final s = filtered[i];
                      // Compute attendance % from stored counters
                      final presentCount = int.tryParse(s['present_count']?.toString() ?? '0') ?? 0;
                      final totalClasses = int.tryParse(s['total_classes']?.toString() ?? '0') ?? 0;
                      final absentCount  = int.tryParse(s['absent_count']?.toString()  ?? '0') ?? 0;
                      final attendancePct = totalClasses > 0
                          ? (presentCount / totalClasses * 100)
                          : 0.0;
                      final attendanceStr = '${attendancePct.toStringAsFixed(1)}%';
                      final pctColor = attendancePct >= 80
                          ? const Color(0xFF10B981)
                          : attendancePct >= 60
                              ? const Color(0xFFF59E0B)
                              : Colors.red;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: pctColor.withValues(alpha: 0.12)),
                                  child: Center(child: Text(
                                    (s['name'] ?? '?').toString().isNotEmpty ? (s['name'] as String)[0].toUpperCase() : '?',
                                    style: TextStyle(color: pctColor, fontWeight: FontWeight.bold, fontSize: 16),
                                  )),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(s['name'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                                  Text('${s['roll'] ?? ''} · Class ${s['class'] ?? '-'}', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text(attendanceStr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: pctColor)),
                                  StatusBadge(label: s['status'] ?? 'active', variant: s['status'] ?? 'active'),
                                ]),
                              ],
                            ),
                            if (totalClasses > 0) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (attendancePct / 100).clamp(0.0, 1.0),
                                  minHeight: 5,
                                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                  valueColor: AlwaysStoppedAnimation(pctColor),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(children: [
                                _statChip(Icons.check_circle_outline, '$presentCount P', const Color(0xFF10B981), isDark),
                                const SizedBox(width: 8),
                                _statChip(Icons.cancel_outlined, '$absentCount A', const Color(0xFFF59E0B), isDark),
                                const SizedBox(width: 8),
                                _statChip(Icons.event_note, '$totalClasses total', const Color(0xFF94A3B8), isDark),
                              ]),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color, bool isDark) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
      ]);

  Widget _buildFilterDropdown({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          items: items.map((i) => DropdownMenuItem(value: i, child: Row(
            children: [
              Icon(icon, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(i, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1E293B))),
            ],
          ))).toList(),
          onChanged: onChanged,
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        ),
      ),
    );
  }
}
