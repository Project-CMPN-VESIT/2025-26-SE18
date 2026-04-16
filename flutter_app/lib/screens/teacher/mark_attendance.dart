import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../layouts/teacher_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class MarkAttendance extends StatefulWidget {
  const MarkAttendance({super.key});

  @override
  State<MarkAttendance> createState() => _MarkAttendanceState();
}

class _MarkAttendanceState extends State<MarkAttendance> {
  final Map<String, String> _attendance = {};

  // Session info
  String _startTime = '09:00';
  String _endTime = '11:30';
  String? _zone;
  String? _centre;

  // Students from Cloud
  List<Map<String, dynamic>> _sheetStudents = [];
  bool _loadingSheet = false;

  final _timeSlots = [
    '07:00', '07:30', '08:00', '08:30', '09:00', '09:30',
    '10:00', '10:30', '11:00', '11:30', '12:00', '12:30',
    '13:00', '13:30', '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30', '17:00', '17:30', '18:00',
  ];

  final _zones = ['North', 'South', 'East', 'West'];
  final _centres = ['East Park Centre', 'North Valley', 'Urban Hub', 'City Square', 'Green Meadows', 'Bright Future'];

  @override
  void initState() {
    super.initState();
    // Pre-fill zone/centre from teacher profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AppAuthProvider>();
      final z = auth.user?['zone'] ?? 'North';
      final c = auth.user?['centre'] ?? 'East Park Centre';
      setState(() {
        _zone = z;
        _centre = c;
      });
      _fetchStudentsFromCloud(z, c);
    });
  }

  Future<void> _fetchStudentsFromCloud(String zone, String centre) async {
    setState(() { _loadingSheet = true; });
    try {
      final dp = context.read<DataProvider>();
      final students = await dp.fetchStudentsByLocation(zone: zone, centre: centre);
      if (mounted) {
        setState(() { _sheetStudents = students; _loadingSheet = false; _attendance.clear(); });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loadingSheet = false; });
      }
    }
  }

  void _mark(String id, String status) => setState(() => _attendance[id] = status);

  @override
  Widget build(BuildContext context) {
    // Use sheet students if available, otherwise fallback to Firestore filtered
    final allStudents = context.watch<DataProvider>().students;
    final firestoreFiltered = _centre != null
        ? allStudents.where((s) => s['centre'] == _centre).toList()
        : allStudents;
    final students = _sheetStudents.isNotEmpty ? _sheetStudents : firestoreFiltered;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enrolledCount = students.length;

    return TeacherLayout(
      child: Column(
        children: [
          const AppHeader(title: 'Mark Attendance', backTo: '/teacher'),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Session Info Card ────────────────────
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Start Time & End Time
                            Row(
                              children: [
                                Expanded(child: _buildDropdown(
                                  icon: Icons.access_time,
                                  label: 'Start Time',
                                  value: _startTime,
                                  items: _timeSlots,
                                  onChanged: (v) => setState(() => _startTime = v!),
                                  isDark: isDark,
                                )),
                                const SizedBox(width: 16),
                                Expanded(child: _buildDropdown(
                                  icon: Icons.timelapse,
                                  label: 'End Time',
                                  value: _endTime,
                                  items: _timeSlots,
                                  onChanged: (v) => setState(() => _endTime = v!),
                                  isDark: isDark,
                                )),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Zone & Centre (Locked for teachers)
                            if (context.read<AppAuthProvider>().role != 'teacher')
                              Row(
                                children: [
                                  Expanded(child: _buildDropdown(
                                    icon: Icons.map_outlined,
                                    label: 'Zone',
                                    value: _zone ?? _zones.first,
                                    items: _zones,
                                    onChanged: (v) { setState(() => _zone = v); if (v != null && _centre != null) _fetchStudentsFromCloud(v, _centre!); },
                                    isDark: isDark,
                                  )),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildDropdown(
                                    icon: Icons.location_on_outlined,
                                    label: 'Centre',
                                    value: _centre ?? _centres.first,
                                    items: _centres,
                                    onChanged: (v) { setState(() => _centre = v); if (_zone != null && v != null) _fetchStudentsFromCloud(_zone!, v); },
                                    isDark: isDark,
                                  )),
                                ],
                              )
                            else 
                              // Display as read-only or info for teachers
                              Row(
                                children: [
                                  Expanded(child: _buildInfoTag(Icons.map_outlined, 'Zone', _zone ?? 'Unknown', isDark)),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildInfoTag(Icons.location_on_outlined, 'Centre', _centre ?? 'Unknown', isDark)),
                                ],
                              ),
                          ],
                        ),
                      ),

                      // ─── Student Roster Header ────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('STUDENT ROSTER', style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              letterSpacing: 1.2,
                            )),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('$enrolledCount Enrolled', style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              )),
                            ),
                          ],
                        ),
                      ),

                      // ─── Student Cards ────────────────────────
                      ...students.map((student) {
                        final id = (student['id'] ?? student['roll'] ?? '').toString();
                        final name = (student['name'] ?? 'Unknown').toString();
                        final roll = (student['roll'] ?? '').toString();
                        final studentClass = (student['class'] ?? '').toString();
                        final initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
                        final status = _attendance[id];

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: status == 'present' ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                   : status == 'absent' ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                                   : status == 'dropout' ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                                   : isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Student info row
                              Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primary.withValues(alpha: 0.15),
                                          AppTheme.primary.withValues(alpha: 0.05),
                                        ],
                                      ),
                                    ),
                                    child: Center(child: Text(initials, style: TextStyle(
                                      color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14,
                                    ))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                                        )),
                                        const SizedBox(height: 2),
                                        Text('ID: #$roll • $studentClass', style: TextStyle(
                                          fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                        )),
                                      ],
                                    ),
                                  ),
                                  Builder(builder: (_) {
                                    final pCnt = int.tryParse(student['present_count']?.toString() ?? '0') ?? 0;
                                    final tCnt = int.tryParse(student['total_classes']?.toString()  ?? '0') ?? 0;
                                    final pct  = tCnt > 0 ? '${(pCnt / tCnt * 100).toStringAsFixed(0)}%' : 'N/A';
                                    return _buildAttendanceBadge(pct, isDark);
                                  }),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Status buttons row
                              Row(
                                children: [
                                  _buildStatusButton(id, 'present', Icons.check_circle_outline, 'PRESENT',
                                    const Color(0xFF10B981), status, isDark),
                                  const SizedBox(width: 8),
                                  _buildStatusButton(id, 'absent', Icons.cancel_outlined, 'ABSENT',
                                    const Color(0xFFEF4444), status, isDark),
                                  const SizedBox(width: 8),
                                  _buildStatusButton(id, 'dropout', Icons.person_off_outlined, 'DROPOUT',
                                    const Color(0xFFF59E0B), status, isDark),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // ─── Sticky Submit Button ─────────────────────
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, -4))],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _submitAttendance(students),
                        icon: const Icon(Icons.groups_outlined, size: 22),
                        label: const Text('Submit Session Attendance'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A5F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dropdown builder ──────────────────────────────────────────
  Widget _buildDropdown({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            )),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              )))).toList(),
              onChanged: onChanged,
              icon: Icon(Icons.keyboard_arrow_down, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // Attendance badge builder
  Widget _buildAttendanceBadge(String percent, bool isDark) {
    final val = int.tryParse(percent.replaceAll('%', '')) ?? 0;
    final color = val >= 80 ? const Color(0xFF10B981) 
               : val >= 60 ? Colors.orange 
               : Colors.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(percent, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800, color: color,
          )),
          Text('ATTENDANCE', style: TextStyle(
            fontSize: 7, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          )),
        ],
      ),
    );
  }

  // ─── Status button builder ─────────────────────────────────────
  Widget _buildStatusButton(String studentId, String statusValue, IconData icon, String label,
      Color color, String? currentStatus, bool isDark) {
    final isSelected = currentStatus == statusValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => _mark(studentId, statusValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? color : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: isSelected ? color : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                letterSpacing: 0.5,
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Submit handler ────────────────────────────────────────────
  Future<void> _submitAttendance(List<Map<String, dynamic>> students) async {
    final unmarked = students.length - _attendance.length;
    if (unmarked > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please mark attendance for all students. $unmarked remaining.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    try {
      final auth = context.read<AppAuthProvider>();
      final dp   = context.read<DataProvider>();
      final todayStr     = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final presentCount = _attendance.values.where((v) => v == 'present').length;
      final absentCount  = _attendance.values.where((v) => v == 'absent').length;
      final dropoutCount = _attendance.values.where((v) => v == 'dropout').length;

      for (final entry in _attendance.entries) {
        await dp.addAttendance({
          'studentId': entry.key,
          'status':    entry.value,
          'date':      todayStr,
        });
      }

      // Refresh student list so attendance % updates immediately
      await dp.refreshStudentsForLocation(
        auth.user?['zone'],
        auth.user?['centre'],
      );
      // Re-fetch for this screen too
      if (_zone != null && _centre != null) {
        await _fetchStudentsFromCloud(_zone!, _centre!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Session submitted! ✓ P:$presentCount  A:$absentCount  D:$dropoutCount'),
        backgroundColor: Colors.green,
      ));
      setState(() => _attendance.clear());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildInfoTag(IconData icon, String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            )),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155).withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Text(value, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          )),
        ),
      ],
    );
  }
}
