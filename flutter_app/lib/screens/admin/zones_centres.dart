import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../../providers/data_provider.dart';
import '../../layouts/admin_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';

class ZonesCentres extends StatefulWidget {
  const ZonesCentres({super.key});

  @override
  State<ZonesCentres> createState() => _ZonesCentresState();
}

class _ZonesCentresState extends State<ZonesCentres> {
  String? _selectedZone;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredCentres = _selectedZone == null 
        ? data.centres 
        : data.centres.where((c) => c['zone'] == _selectedZone).toList();

    return AdminLayout(
      child: Column(children: [
        AppHeader(title: 'Zones & Centres', backTo: '/admin', rightActions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add, color: AppTheme.primary),
            onSelected: (val) => context.go(val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: '/admin/zones/add', child: Text('Add New Zone')),
              const PopupMenuItem(value: '/admin/centres/add', child: Text('Add New Centre')),
            ],
          ),
        ]),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Zones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          const SizedBox(height: 12),
          ...data.zones.map((z) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(z['name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                StatusBadge(label: z['status'], variant: z['status']),
              ]),
              const SizedBox(height: 8),
              Text('Coordinator: ${z['coordinator']}', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              const SizedBox(height: 8),
              Row(children: [
                _infoChip(Icons.location_city, '${z['centres']} centres', isDark),
                const SizedBox(width: 12),
                _infoChip(Icons.person, '${z['teachers']} teachers', isDark),
                const SizedBox(width: 12),
                _infoChip(Icons.school, '${z['students']} students', isDark),
              ]),
            ]),
          )),
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Centres', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedZone,
                  icon: const Icon(Icons.filter_list, color: AppTheme.primary, size: 18),
                  hint: Text('All Zones', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13),
                  underline: Container(height: 1, color: AppTheme.primary.withValues(alpha: 0.3)),
                  onChanged: (val) => setState(() => _selectedZone = val),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Show All Zones')),
                    ...data.zones.map((z) => DropdownMenuItem(
                      value: z['name'] as String,
                      child: Text(z['name']),
                    )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (filteredCentres.isEmpty)
             const Padding(
               padding: EdgeInsets.symmetric(vertical: 40),
               child: Center(child: Text('No centres found in this zone.')),
             )
          else
            ...filteredCentres.map((c) => GestureDetector(
              onTap: () => _showCentreDetails(context, c, isDark),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))),
                child: Row(children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.location_city, color: AppTheme.primary, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c['name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                    Text(c['address'] ?? 'Address not available', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                  ])),
                  StatusBadge(label: c['zone'], variant: 'teacher'),
                ]),
              ),
            )),
          const SizedBox(height: 100),
        ]))),
      ]),
    );
  }

  Widget _infoChip(IconData icon, String text, bool isDark) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: AppTheme.primary),
    const SizedBox(width: 4),
    Text(text, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
  ]);

  void _showCentreDetails(BuildContext context, Map<String, dynamic> c, bool isDark) {
    final centreName = c['name'] as String;
    final address = c['address']?.toString() ?? 'Address not available';
    
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
              const Icon(Icons.location_on, color: AppTheme.primary, size: 20),
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
  }
}
