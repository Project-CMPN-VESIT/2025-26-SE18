import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../layouts/coordinator_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Compute total students across all centres functionally
    int totalStudents = data.students.length;

    // Compute real average attendance logically across all loaded students
    int overallTotalClasses = 0;
    int overallTotalPresent = 0;
    for (var s in data.students) {
      overallTotalClasses += (s['totalClasses'] as int? ?? 0);
      overallTotalPresent += (s['presentCount'] as int? ?? 0);
    }
    final avgAttendance = overallTotalClasses > 0 ? '${(overallTotalPresent / overallTotalClasses * 100).toStringAsFixed(0)}%' : '0%';

    return CoordinatorLayout(
      child: Column(children: [
        const AppHeader(title: 'Analytics', backTo: '/coordinator'),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
          Row(children: [
            Expanded(child: StatCard(icon: Icons.school, value: '$totalStudents', label: 'Students')),
            const SizedBox(width: 12),
            Expanded(child: StatCard(icon: Icons.person, value: '${data.teachers.length}', label: 'Teachers')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: StatCard(icon: Icons.location_city, value: '${data.centres.length}', label: 'Centres', iconBg: const Color(0xFFF0FDF4), iconColor: const Color(0xFF10B981))),
            const SizedBox(width: 12),
            Expanded(child: StatCard(icon: Icons.check_circle, value: avgAttendance, label: 'Avg Attendance', iconBg: const Color(0xFFFFFBEB), iconColor: const Color(0xFFF59E0B))),
          ]),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Centre Analytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.centres.length,
            itemBuilder: (context, index) {
              final c = data.centres[index];
              final centreName = c['name'] as String;

              // Compute attendance dynamically for the centre
              final centreStudents = data.students.where((s) => s['centre'] == centreName).toList();
              int centreClasses = 0;
              int centrePresent = 0;
              for (var s in centreStudents) {
                centreClasses += (s['totalClasses'] as int? ?? 0);
                centrePresent += (s['presentCount'] as int? ?? 0);
              }
              final avgAtt = centreClasses > 0 ? '${(centrePresent / centreClasses * 100).toStringAsFixed(0)}%' : '0%';

              // Get Exams for this centre
              final centreExams = data.examResults.where((e) => e['centre'] == centreName).toList();

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(centreName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                          child: Text('Att: $avgAtt', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                        ),
                      ],
                    ),
                    if (centreExams.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Text('Recent Exams', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      const SizedBox(height: 8),
                      ...centreExams.map((exam) {
                        final marksList = (exam['marks'] as List<dynamic>? ?? []);
                        double totalMks = 0;
                        int markCount = 0;
                        for (var m in marksList) {
                          final mv = double.tryParse(m['marks']?.toString() ?? '');
                          if (mv != null) { totalMks += mv; markCount++; }
                        }
                        final avgExam = markCount > 0 ? (totalMks / markCount).toStringAsFixed(1) : '0.0';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('${exam['topic']} (${exam['date']})', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF334155)))),
                              Text('Avg: $avgExam', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ));
            },
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Exam Results', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
            ),
          ),
          if (data.examResults.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No exams conducted yet', style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)))),
            )
          else
            ...data.examResults.map((exam) {
              final marksList = (exam['marks'] as List<dynamic>? ?? []);
              double totalMks = 0;
              int markCount = 0;
              for (var m in marksList) {
                final mv = double.tryParse(m['marks']?.toString() ?? '');
                if (mv != null) { totalMks += mv; markCount++; }
              }
              final avgScore = markCount > 0 ? (totalMks / markCount).toStringAsFixed(1) : '0.0';
              final topic = exam['topic']?.toString() ?? 'Untitled';
              final date = exam['date']?.toString() ?? '';
              final centre = exam['centre']?.toString() ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.quiz, color: AppTheme.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(topic, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                            const SizedBox(height: 4),
                            Text('$date  •  $centre', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text('Avg: $avgScore', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 100),
        ]))),
      ]),
    );
  }
}
