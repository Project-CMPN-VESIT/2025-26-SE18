import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../layouts/teacher_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';

class TeachingResources extends StatelessWidget {
  const TeachingResources({super.key});

  @override
  Widget build(BuildContext context) {
    final resources = context.watch<DataProvider>().resources;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData getIcon(String type) {
      switch (type) {
        case 'pdf': return Icons.picture_as_pdf;
        case 'image': return Icons.image;
        case 'doc': return Icons.description;
        default: return Icons.insert_drive_file;
      }
    }

    Color getColor(String type) {
      switch (type) {
        case 'pdf': return const Color(0xFFEF4444);
        case 'image': return const Color(0xFF10B981);
        case 'doc': return const Color(0xFF3B82F6);
        default: return const Color(0xFF64748B);
      }
    }

    return TeacherLayout(
      child: Column(
        children: [
          const AppHeader(title: 'Teaching Resources', backTo: '/teacher'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upload Zone
                  FileUploadZone(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File uploads are not available yet — Cloud Storage is not enabled.'), backgroundColor: Colors.orange));
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('Your Resources', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  ...resources.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: getColor(r['type']).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Icon(getIcon(r['type']), color: getColor(r['type']), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['name'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                              Text('${r['size']} · ${r['date']}', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                        StatusBadge(label: r['subject'], variant: 'teacher'),
                      ],
                    ),
                  )),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
