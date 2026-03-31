import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../layouts/teacher_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class ExamResults extends StatefulWidget {
  const ExamResults({super.key});

  @override
  State<ExamResults> createState() => _ExamResultsState();
}

class _ExamResultsState extends State<ExamResults> {
  bool _showForm = false;
  String? _zone;
  String? _centre;
  String _topic = '';
  DateTime _examDate = DateTime.now();
  final _topicCtrl = TextEditingController();

  // Students loaded for mark entry
  List<Map<String, dynamic>> _students = [];
  bool _loadingStudents = false;
  final Map<String, TextEditingController> _markControllers = {};


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AppAuthProvider>();
      setState(() {
        _zone = auth.user?['zone'] ?? 'North';
        _centre = auth.user?['centre'] ?? 'East Park Centre';
      });
    });
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    for (final ctrl in _markControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStudents(String z, String c) async {
    setState(() { _loadingStudents = true; });
    try {
      final dp = context.read<DataProvider>();
      final students = await dp.fetchStudentsByLocation(zone: z, centre: c);
      // Create controllers for each student
      for (final ctrl in _markControllers.values) {
        ctrl.dispose();
      }
      _markControllers.clear();
      for (final s in students) {
        final key = (s['roll'] ?? s['name'] ?? '').toString();
        _markControllers[key] = TextEditingController();
      }
      if (mounted) {
        setState(() { _students = students; _loadingStudents = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loadingStudents = false; });
      }
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _examDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _examDate = date);
  }

  Future<void> _submitExam(String z, String c) async {
    if (_topicCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the exam topic.'), backgroundColor: Colors.orange));
      return;
    }
    if (_students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No students loaded. Select zone/centre first.'), backgroundColor: Colors.orange));
      return;
    }

    // Collect marks
    final marks = <Map<String, dynamic>>[];
    for (final s in _students) {
      final key = (s['roll'] ?? s['name'] ?? '').toString();
      final marksText = _markControllers[key]?.text ?? '';
      if (marksText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter marks for ${s['name']}'), backgroundColor: Colors.orange));
        return;
      }
      marks.add({
        'name': s['name'] ?? '',
        'roll': s['roll'] ?? '',
        'marks': int.tryParse(marksText) ?? 0,
      });
    }

    try {
      final auth = context.read<AppAuthProvider>();
      final dateStr = DateFormat('yyyy-MM-dd').format(_examDate);
      await context.read<DataProvider>().addExamResult({
        'date': dateStr,
        'topic': _topicCtrl.text,
        'zone': z,
        'centre': c,
        'marks': marks,
      });
      if (mounted) {
        // Clear form
        _topicCtrl.clear();
        for (final ctrl in _markControllers.values) {
          ctrl.clear();
        }
        setState(() => _showForm = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: const Text('Exam results submitted successfully! ✅'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final rawResults = dp.examResults;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allZones = dp.zones.map((z) => z['name'] as String).toList();
    if (allZones.isEmpty) allZones.add('Thane');
    if (_zone != null && !allZones.contains(_zone)) _zone = allZones.first;
    final effectiveZone = _zone ?? allZones.first;

    final allCentres = dp.centres.where((c) => c['zone'] == effectiveZone).map((c) => c['name'] as String).toList();
    if (allCentres.isEmpty) allCentres.add('Tejaswini');
    if (_centre != null && !allCentres.contains(_centre)) _centre = allCentres.first;
    final effectiveCentre = _centre ?? allCentres.first;

    // Only show new-format exams that have a marks array
    final existingResults = rawResults.where((r) => r['marks'] is List && (r['marks'] as List).isNotEmpty).toList();

    return TeacherLayout(
      child: Column(
        children: [
          AppHeader(
            title: 'Exam Results',
            backTo: '/teacher',
            rightActions: [
              IconButton(
                icon: Icon(_showForm ? Icons.close : Icons.add, color: AppTheme.primary),
                onPressed: () {
                  setState(() => _showForm = !_showForm);
                  if (_showForm && _students.isEmpty) _loadStudents(effectiveZone, effectiveCentre);
                },
              ),
            ],
          ),
          Expanded(
            child: !_showForm && existingResults.isEmpty
              // ─── Empty State ───
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_outlined, size: 64, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      const SizedBox(height: 16),
                      Text('No exams conducted yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                      const SizedBox(height: 8),
                      Text('Tap + to add your first exam results', style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))),
                    ],
                  ),
                )
              : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── New Exam Form ───
                  if (_showForm) ...[
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('New Exam', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                          const SizedBox(height: 16),

                          // Date picker
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                  const SizedBox(width: 10),
                                  Text('Exam Date: ${DateFormat('dd MMM yyyy').format(_examDate)}', style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Zone & Centre
                          Row(
                            children: [
                              Expanded(child: _buildStaticField(Icons.map_outlined, 'Zone', effectiveZone, isDark)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStaticField(Icons.location_on_outlined, 'Centre', effectiveCentre, isDark)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Topic
                          TextField(
                            controller: _topicCtrl,
                            decoration: InputDecoration(
                              hintText: 'Exam Topic (e.g., Math Chapter 5)',
                              prefixIcon: Icon(Icons.topic, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Student marks section
                          Row(
                            children: [
                              Icon(Icons.people, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text('STUDENT MARKS (${_students.length})', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              const Spacer(),
                              if (_loadingStudents)
                                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (_students.isEmpty && !_loadingStudents)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: const Text('Select zone & centre to load students', style: TextStyle(fontSize: 13, color: Color(0xFF92400E))),
                            ),

                          // Dynamic student marks inputs
                          ..._students.map((s) {
                            final key = (s['roll'] ?? s['name'] ?? '').toString();
                            final name = s['name']?.toString() ?? 'Unknown';
                            final roll = s['roll']?.toString() ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withValues(alpha: 0.1)),
                                    child: Center(child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14))),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                                        Text('Roll: $roll', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 70,
                                    child: TextField(
                                      controller: _markControllers[key],
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        hintText: 'Marks',
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        isDense: true,
                                      ),
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity, height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _students.isNotEmpty ? () => _submitExam(effectiveZone, effectiveCentre) : null,
                              icon: const Icon(Icons.cloud_upload),
                              label: const Text('Submit & Save to Cloud'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ─── Existing Results Feed ───
                  if (existingResults.isNotEmpty) ...[
                    Text('Past Exams', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                    const SizedBox(height: 10),
                    ...existingResults.map((r) {
                      final marksList = r['marks'] as List<dynamic>? ?? [];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r['topic']?.toString() ?? 'Exam', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                                      Text('${r['date']} · ${r['zone']} - ${r['centre']}', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text('${marksList.length} students', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                ),
                              ],
                            ),
                            if (marksList.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              ...marksList.take(5).map((m) {
                                final mark = m as Map<String, dynamic>? ?? {};
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${mark['name']} (${mark['roll']})', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
                                      Text('${mark['marks']}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                                    ],
                                  ),
                                );
                              }),
                              if (marksList.length > 5)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('+ ${marksList.length - 5} more...', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                                ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticField(IconData icon, String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        ]),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Text(value, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1E293B))),
        ),
      ],
    );
  }
}
