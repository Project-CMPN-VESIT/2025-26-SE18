import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../layouts/admin_layout.dart';
import '../../widgets/app_widgets.dart';


class LeaveManagement extends StatelessWidget {
  const LeaveManagement({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AdminLayout(
      child: Column(children: [
        const AppHeader(title: 'Leave Management', backTo: '/admin'),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
          children: data.leaves.map((l) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l['name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  Text('${l['zone']} Zone', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                ])),
                StatusBadge(label: l['status'], variant: l['status']),
              ]),
              const SizedBox(height: 8),
              Text('${l['type']} · ${l['days']} day(s)', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              Text('${l['from']} → ${l['to']}', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              const SizedBox(height: 4),
              Text(l['reason'], style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),

            ]),
          )).toList(),
        ))),
      ]),
    );
  }
}
