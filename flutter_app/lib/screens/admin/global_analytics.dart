import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../layouts/admin_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';

class GlobalAnalytics extends StatelessWidget {
  const GlobalAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AdminLayout(
      child: Column(children: [
        const AppHeader(title: 'Global Analytics', backTo: '/admin'),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
          Row(children: [
            Expanded(child: StatCard(icon: Icons.map, value: '${data.zones.length}', label: 'Zones', iconBg: const Color(0xFFEFF6FF), iconColor: AppTheme.primary)),
            const SizedBox(width: 12),
            Expanded(child: StatCard(icon: Icons.location_city, value: '${data.centres.length}', label: 'Centres', iconBg: const Color(0xFFF0FDF4), iconColor: const Color(0xFF10B981))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: StatCard(icon: Icons.school, value: '${data.students.length}', label: 'Students', trend: '+8%', iconBg: const Color(0xFFFAF5FF), iconColor: const Color(0xFF8B5CF6))),
            const SizedBox(width: 12),
            Expanded(child: StatCard(icon: Icons.person, value: '${data.teachers.length}', label: 'Teachers', iconBg: const Color(0xFFFFFBEB), iconColor: const Color(0xFFF59E0B))),
          ]),
          const SizedBox(height: 20),

          // Enrollment chart
          AppCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.trending_up, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Enrollment Growth', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
            ]),
            const SizedBox(height: 16),
            SizedBox(height: 150, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [450.0, 520.0, 580.0, 640.0, 720.0, 850.0, 920.0].asMap().entries.map((e) {
              final months = ['Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan'];
              return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${e.value.toInt()}', style: TextStyle(fontSize: 8, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                const SizedBox(height: 4),
                Expanded(child: Align(alignment: Alignment.bottomCenter, child: FractionallySizedBox(heightFactor: e.value / 1000.0, child: Container(decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.primary, AppTheme.primaryDark]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ))))),
                const SizedBox(height: 4),
                Text(months[e.key], style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
              ])));
            }).toList())),
          ])),
          const SizedBox(height: 16),

          // Zone Performance
          AppCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.bar_chart, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Zone Performance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
            ]),
            const SizedBox(height: 16),
            ...data.zones.map((z) {
              final attendanceStr = z['attendance']?.toString() ?? '0%';
              final percent = double.tryParse(attendanceStr.replaceAll('%', '')) ?? 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(z['name'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                    Text(attendanceStr, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                    value: (percent / 100.0).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                  )),
                ]),
              );
            }),
          ])),
          const SizedBox(height: 100),
        ]))),
      ]),
    );
  }
}
