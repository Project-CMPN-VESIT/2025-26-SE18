import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_provider.dart';
import '../../layouts/coordinator_layout.dart';
import '../../widgets/app_widgets.dart';


class LeaveApprovals extends StatelessWidget {
  const LeaveApprovals({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CoordinatorLayout(
      child: Column(children: [
        const AppHeader(title: 'Leave Approvals', backTo: '/coordinator'),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
          children: data.leaves.map((l) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(l['name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)))),
                StatusBadge(label: l['status'], variant: l['status']),
              ]),
              const SizedBox(height: 8),
              Text('${l['type']} · ${l['days']} day(s)', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              Text('${l['from']} → ${l['to']}', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              const SizedBox(height: 4),
              Text(l['reason'], style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
              if (l['status'] == 'pending') ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: SizedBox(height: 36, child: ElevatedButton(
                    onPressed: () async { try { await data.updateLeave(l['id'], {'status': 'approved'}); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave approved'), backgroundColor: Colors.green)); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); } },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Approve', style: TextStyle(fontSize: 12)),
                  ))),
                  const SizedBox(width: 8),
                  Expanded(child: SizedBox(height: 36, child: ElevatedButton(
                    onPressed: () async { try { await data.updateLeave(l['id'], {'status': 'denied'}); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave denied'), backgroundColor: Colors.red)); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)); } },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Deny', style: TextStyle(fontSize: 12)),
                  ))),
                ]),
              ],
            ]),
          )).toList(),
        ))),
      ]),
    );
  }
}
