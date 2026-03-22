import 'package:flutter/material.dart';
import '../../layouts/coordinator_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reports = [
      {'title': 'Monthly Attendance Report', 'desc': 'Attendance summary for all centres', 'icon': Icons.event_available, 'date': 'Feb 2025'},
      {'title': 'Student Enrollment Report', 'desc': 'New registrations and active students', 'icon': Icons.person_add, 'date': 'Feb 2025'},
      {'title': 'CSR Progress Report', 'desc': 'Corporate social responsibility metrics', 'icon': Icons.assessment, 'date': 'Q4 2024'},
      {'title': 'Teacher Performance Report', 'desc': 'Teaching hours and student outcomes', 'icon': Icons.grade, 'date': 'Jan 2025'},
    ];

    return CoordinatorLayout(
      child: Column(children: [
        const AppHeader(title: 'Reports', backTo: '/coordinator'),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
          children: reports.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(r['icon'] as IconData, color: AppTheme.primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r['title'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                Text(r['desc'] as String, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
              ])),
              Column(children: [
                Text(r['date'] as String, style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                const SizedBox(height: 4),
                const Icon(Icons.download, color: AppTheme.primary, size: 20),
              ]),
            ]),
          )).toList(),
        ))),
      ]),
    );
  }
}
