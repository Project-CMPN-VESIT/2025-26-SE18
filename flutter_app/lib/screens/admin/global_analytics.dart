import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/data_provider.dart';
import '../../layouts/admin_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';

class GlobalAnalytics extends StatefulWidget {
  const GlobalAnalytics({super.key});

  @override
  State<GlobalAnalytics> createState() => _GlobalAnalyticsState();
}

class _GlobalAnalyticsState extends State<GlobalAnalytics> {
  final _supabase = Supabase.instance.client;

  // Attendance summary: { zoneName: { march: { present, absent, dropout, total }, april: {...} } }
  Map<String, Map<String, Map<String, int>>> _attendanceSummary = {};
  bool _loadingAttendance = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceSummary();
  }

  Future<void> _fetchAttendanceSummary() async {
    setState(() => _loadingAttendance = true);
    try {
      // Fetch all attendance for March & April 2026
      final data = await _supabase
          .from('attendance')
          .select('status, date, students(zone)')
          .gte('date', '2026-03-01')
          .lte('date', '2026-04-30');

      final Map<String, Map<String, Map<String, int>>> result = {};

      for (final row in data as List) {
        final zone = (row['students'] as Map?)?['zone']?.toString() ?? 'Unknown';
        final status = row['status']?.toString() ?? '';
        final dateStr = row['date']?.toString() ?? '';
        if (dateStr.length < 7) continue;

        final monthNum = int.tryParse(dateStr.substring(5, 7)) ?? 0;
        final monthKey = monthNum == 3 ? 'march' : monthNum == 4 ? 'april' : null;
        if (monthKey == null) continue;

        result.putIfAbsent(zone, () => {});
        result[zone]!.putIfAbsent(monthKey, () => {'present': 0, 'absent': 0, 'dropout': 0, 'total': 0});
        result[zone]![monthKey]!['total'] = (result[zone]![monthKey]!['total'] ?? 0) + 1;
        if (status == 'present') {
          result[zone]![monthKey]!['present'] = (result[zone]![monthKey]!['present'] ?? 0) + 1;
        } else if (status == 'absent') {
          result[zone]![monthKey]!['absent'] = (result[zone]![monthKey]!['absent'] ?? 0) + 1;
        } else if (status == 'dropout') {
          result[zone]![monthKey]!['dropout'] = (result[zone]![monthKey]!['dropout'] ?? 0) + 1;
        }
      }

      if (mounted) setState(() { _attendanceSummary = result; _loadingAttendance = false; });
    } catch (e) {
      debugPrint('GlobalAnalytics: fetchAttendanceSummary error: $e');
      if (mounted) setState(() => _loadingAttendance = false);
    }
  }

  /// Returns attendance % for a zone+month, or null if no data
  double? _attendanceRate(String zone, String month) {
    final m = _attendanceSummary[zone]?[month];
    if (m == null || (m['total'] ?? 0) == 0) return null;
    final present = m['present'] ?? 0;
    final total = m['total'] ?? 1;
    return (present / total) * 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Aggregate totals across all zones
    int totalPresent = 0, totalAbsent = 0, totalDropout = 0;
    for (final zone in _attendanceSummary.values) {
      for (final month in zone.values) {
        totalPresent  += month['present']  ?? 0;
        totalAbsent   += month['absent']   ?? 0;
        totalDropout  += month['dropout']  ?? 0;
      }
    }
    final grandTotal = totalPresent + totalAbsent + totalDropout;
    final overallRate = grandTotal > 0 ? (totalPresent / grandTotal * 100) : 0.0;

    return AdminLayout(
      child: Column(children: [
        AppHeader(
          title: 'Global Analytics',
          backTo: '/admin',
          rightActions: [
            TextButton.icon(
              onPressed: () => context.go('/admin/attendance-summary'),
              icon: const Icon(Icons.table_chart, color: AppTheme.primary, size: 18),
              label: const Text('Full Report', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
            ),
          ],
        ),
        Expanded(child: RefreshIndicator(
          onRefresh: () async {
            await data.refreshAllData();
            await _fetchAttendanceSummary();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(children: [

              // ── Top stat cards ─────────────────────────────
              Row(children: [
                Expanded(child: StatCard(icon: Icons.map, value: '${data.zones.length}', label: 'Zones', iconBg: const Color(0xFFEFF6FF), iconColor: AppTheme.primary)),
                const SizedBox(width: 12),
                Expanded(child: StatCard(icon: Icons.location_city, value: '${data.centres.length}', label: 'Centres', iconBg: const Color(0xFFF0FDF4), iconColor: const Color(0xFF10B981))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: StatCard(icon: Icons.school, value: '${data.students.length}', label: 'Students', iconBg: const Color(0xFFFAF5FF), iconColor: const Color(0xFF8B5CF6))),
                const SizedBox(width: 12),
                Expanded(child: StatCard(icon: Icons.how_to_reg, value: '${overallRate.toStringAsFixed(1)}%', label: 'Attendance', iconBg: const Color(0xFFFFFBEB), iconColor: const Color(0xFFF59E0B))),
              ]),
              const SizedBox(height: 20),

              // ── Mar & Apr Attendance Bar Chart ────────────
              AppCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.bar_chart, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Attendance — Mar & Apr 2026', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                ]),
                const SizedBox(height: 6),
                Text('Total: $grandTotal sessions | Present: $totalPresent | Absent: $totalAbsent | Dropout: $totalDropout',
                  style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                const SizedBox(height: 16),

                if (_loadingAttendance)
                  const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(),
                  ))
                else if (_attendanceSummary.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(children: [
                      Icon(Icons.info_outline, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 32),
                      const SizedBox(height: 8),
                      Text('No attendance data yet.\nImport the Excel files first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ]),
                  ))
                else
                  SizedBox(
                    height: 160,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: data.zones.map((z) {
                        final zoneName = z['name']?.toString() ?? '';
                        final marchRate = _attendanceRate(zoneName, 'march');
                        final aprilRate = _attendanceRate(zoneName, 'april');
                        final barRate = aprilRate ?? marchRate ?? 0.0;
                        return Expanded(child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                            Text('${barRate.toStringAsFixed(0)}%', style: TextStyle(fontSize: 8, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Expanded(child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: (barRate / 100.0).clamp(0.05, 1.0),
                                child: Container(decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: barRate >= 75
                                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                      : barRate >= 50
                                        ? [AppTheme.primary, AppTheme.primaryDark]
                                        : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                                  ),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                )),
                              ),
                            )),
                            const SizedBox(height: 4),
                            Text(zoneName.length > 5 ? zoneName.substring(0, 5) : zoneName,
                              style: TextStyle(fontSize: 8, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                          ]),
                        ));
                      }).toList(),
                    ),
                  ),
                // Legend
                const SizedBox(height: 12),
                Row(children: [
                  _legendDot(const Color(0xFF10B981)), const SizedBox(width: 4),
                  Text('≥75%', style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  const SizedBox(width: 12),
                  _legendDot(AppTheme.primary), const SizedBox(width: 4),
                  Text('50-74%', style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  const SizedBox(width: 12),
                  _legendDot(const Color(0xFFF59E0B)), const SizedBox(width: 4),
                  Text('<50%', style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                ]),
              ])),
              const SizedBox(height: 16),

              // ── Zone Performance with real rates ──────────
              AppCard(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.trending_up, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Zone Performance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                ]),
                const SizedBox(height: 4),
                Text('March & April 2026 combined attendance rate', style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                const SizedBox(height: 16),

                if (_loadingAttendance)
                  const Center(child: CircularProgressIndicator())
                else if (data.zones.isEmpty)
                  Center(child: Text('No zones yet', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))))
                else
                  ...data.zones.map((z) {
                    final zoneName = z['name']?.toString() ?? '';
                    final marchRate = _attendanceRate(zoneName, 'march');
                    final aprilRate = _attendanceRate(zoneName, 'april');

                    // Compute combined rate
                    final marchData = _attendanceSummary[zoneName]?['march'];
                    final aprilData = _attendanceSummary[zoneName]?['april'];
                    final combinedPresent = (marchData?['present'] ?? 0) + (aprilData?['present'] ?? 0);
                    final combinedTotal   = (marchData?['total']   ?? 0) + (aprilData?['total']   ?? 0);
                    final combinedRate    = combinedTotal > 0 ? (combinedPresent / combinedTotal * 100) : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(child: Text(zoneName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)))),
                          Row(children: [
                            if (marchRate != null) _monthPill('Mar', marchRate, isDark),
                            if (aprilRate != null) ...[const SizedBox(width: 4), _monthPill('Apr', aprilRate, isDark)],
                          ]),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                          value: (combinedRate / 100.0).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation(
                            combinedRate >= 75 ? const Color(0xFF10B981) : AppTheme.primary,
                          ),
                        )),
                        const SizedBox(height: 4),
                        Row(children: [
                          Text('${z['students'] ?? 0} students  •  ${combinedRate.toStringAsFixed(1)}% overall',
                            style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                        ]),
                      ]),
                    );
                  }),
              ])),
              const SizedBox(height: 16),

              // ── Quick action to see full report ───────────
              GestureDetector(
                onTap: () => context.go('/admin/attendance-summary'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.table_chart, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('View Full Attendance Report', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      const Text('Centre-wise breakdown for Mar & Apr 2026', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ])),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ]),
                ),
              ),
              const SizedBox(height: 100),
            ]),
          ),
        )),
      ]),
    );
  }

  Widget _legendDot(Color color) => Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  Widget _monthPill(String label, double rate, bool isDark) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: rate >= 75 ? const Color(0xFF10B981).withValues(alpha: 0.15) : AppTheme.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text('$label: ${rate.toStringAsFixed(0)}%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
      color: rate >= 75 ? const Color(0xFF10B981) : AppTheme.primary)),
  );
}
