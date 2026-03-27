import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../providers/data_provider.dart';
import '../../layouts/coordinator_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';

class ZoneCentres extends StatelessWidget {
  const ZoneCentres({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CoordinatorLayout(
      child: Column(children: [
        const AppHeader(title: 'Centres', backTo: '/coordinator'),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Centres Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          const SizedBox(height: 12),
          ...data.centres.map((c) {
            final centreName = c['name'] as String;
            final teacherCount = data.teachers.where((t) => t['centre'] == centreName).length;
            final displayStudents = data.students.where((s) => s['centre'] == centreName).length;
            final address = c['address']?.toString() ?? 'Address not available';

            return GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
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
                        Text(centreName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                        const SizedBox(height: 16),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(Icons.location_on, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(address, style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.5))),
                        ]),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.map),
                            label: const Text('Open in Google Maps', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              final mapLink = c['mapLink']?.toString() ?? '';
                              if (mapLink.startsWith('http')) {
                                url_launcher.launchUrl(Uri.parse(mapLink), mode: url_launcher.LaunchMode.externalApplication);
                              } else {
                                final query = Uri.encodeComponent(address != 'Address not available' ? address : centreName);
                                final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
                                url_launcher.launchUrl(url, mode: url_launcher.LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(centreName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)))),
                    StatusBadge(label: c['zone'] ?? '', variant: 'teacher'),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.person, size: 14, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text('$teacherCount teachers', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    const SizedBox(width: 16),
                    Icon(Icons.school, size: 14, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text('$displayStudents students', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  ]),
                ]),
              ),
            );
          }),
          const SizedBox(height: 100),
        ]))),
      ]),
    );
  }
}
