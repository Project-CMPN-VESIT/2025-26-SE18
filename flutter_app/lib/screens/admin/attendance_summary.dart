import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../layouts/admin_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';

/// Attendance Summary Screen
/// Shows a centre-wise breakdown of March & April 2026 attendance.
/// This is the "full report" screen built for the college presentation.
class AttendanceSummaryScreen extends StatefulWidget {
  const AttendanceSummaryScreen({super.key});

  @override
  State<AttendanceSummaryScreen> createState() => _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  // Data: { centreName: { month: { present, absent, dropout, total, students } } }
  Map<String, Map<String, Map<String, int>>> _centreData = {};
  final Map<String, String> _centreToZone = {};
  bool _loading = true;
  String? _selectedZone; // null = All Zones

  final _months = ['march', 'april'];
  final _monthLabels = {'march': 'March 2026', 'april': 'April 2026'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Fetch attendance joined with student zone and centre info
      final data = await _supabase
          .from('attendance')
          .select('status, date, students(zone, centre)')
          .gte('date', '2026-03-01')
          .lte('date', '2026-04-30');

      // Fetch student counts per centre
      final studentCounts = await _supabase
          .from('students')
          .select('centre, zone');

      // Build centre→zone map and student counts
      final Map<String, int> centreStudentCount = {};
      for (final s in studentCounts as List) {
        final c = s['centre']?.toString() ?? '';
        centreStudentCount[c] = (centreStudentCount[c] ?? 0) + 1;
        _centreToZone[c] = s['zone']?.toString() ?? '';
      }

      final Map<String, Map<String, Map<String, int>>> result = {};

      for (final row in data as List) {
        final student = row['students'] as Map?;
        final centre = student?['centre']?.toString() ?? 'Unknown';
        final zone   = student?['zone']?.toString()   ?? '';
        final status = row['status']?.toString() ?? '';
        final dateStr = row['date']?.toString() ?? '';
        if (dateStr.length < 7) continue;

        final monthNum = int.tryParse(dateStr.substring(5, 7)) ?? 0;
        final monthKey = monthNum == 3 ? 'march' : monthNum == 4 ? 'april' : null;
        if (monthKey == null) continue;

        _centreToZone[centre] = zone;
        result.putIfAbsent(centre, () => {});
        result[centre]!.putIfAbsent(monthKey, () => {'present': 0, 'absent': 0, 'dropout': 0, 'total': 0, 'students': 0});
        result[centre]![monthKey]!['total'] = (result[centre]![monthKey]!['total'] ?? 0) + 1;
        result[centre]![monthKey]!['students'] = centreStudentCount[centre] ?? 0;
        if (status == 'present') {
          result[centre]![monthKey]!['present'] = (result[centre]![monthKey]!['present'] ?? 0) + 1;
        } else if (status == 'absent') {
          result[centre]![monthKey]!['absent'] = (result[centre]![monthKey]!['absent'] ?? 0) + 1;
        } else if (status == 'dropout') {
          result[centre]![monthKey]!['dropout'] = (result[centre]![monthKey]!['dropout'] ?? 0) + 1;
        }
      }

      if (mounted) setState(() { _centreData = result; _loading = false; });
    } catch (e) {
      debugPrint('AttendanceSummary: load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> get _filteredCentres {
    return _centreData.keys.where((c) {
      if (_selectedZone == null) return true;
      return (_centreToZone[c] ?? '') == _selectedZone;
    }).toList()..sort();
  }

  Set<String> get _allZones => _centreToZone.values.toSet();

  double _rate(String centre, String month) {
    final m = _centreData[centre]?[month];
    if (m == null || (m['total'] ?? 0) == 0) return 0.0;
    return ((m['present'] ?? 0) / (m['total'] ?? 1)) * 100;
  }

  Color _rateColor(double rate) {
    if (rate >= 75) return const Color(0xFF10B981);
    if (rate >= 50) return AppTheme.primary;
    if (rate > 0)   return const Color(0xFFF59E0B);
    return const Color(0xFF94A3B8);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AdminLayout(
      child: Column(children: [
        AppHeader(title: 'Attendance Report', backTo: '/admin/analytics'),

        // ── Zone filter chips ────────────────────────────────────
        if (!_loading && _allZones.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              _filterChip('All Zones', null, isDark),
              ..._allZones.map((z) => _filterChip(z, z, isDark)),
            ]),
          ),

        // ── Month tabs ───────────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            tabs: const [Tab(text: 'March 2026'), Tab(text: 'April 2026')],
          ),
        ),
        const SizedBox(height: 8),

        // ── Tab views ────────────────────────────────────────────
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _months.map((month) => _buildMonthTab(month, isDark)).toList(),
            ),
        ),
      ]),
    );
  }

  Widget _filterChip(String label, String? value, bool isDark) {
    final selected = _selectedZone == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedZone = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primary : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)))),
      ),
    );
  }

  Widget _buildMonthTab(String month, bool isDark) {
    final centres = _filteredCentres;

    if (centres.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.info_outline, size: 40, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        const SizedBox(height: 12),
        Text('No attendance data for ${_monthLabels[month]}.\nImport the Excel files first.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
      ]));
    }

    // Compute summary totals for this month
    int sumPresent = 0, sumAbsent = 0, sumDropout = 0, sumTotal = 0;
    for (final c in centres) {
      final m = _centreData[c]?[month];
      if (m == null) continue;
      sumPresent  += m['present']  ?? 0;
      sumAbsent   += m['absent']   ?? 0;
      sumDropout  += m['dropout']  ?? 0;
      sumTotal    += m['total']    ?? 0;
    }
    final overallRate = sumTotal > 0 ? (sumPresent / sumTotal * 100) : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        // ── Month summary banner ─────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0F1B3E), AppTheme.primary]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_monthLabels[month]!, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Text('${overallRate.toStringAsFixed(1)}% Overall Attendance',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('$sumPresent present · $sumAbsent absent · $sumDropout dropout · $sumTotal sessions',
                style: const TextStyle(color: Colors.white60, fontSize: 10)),
            ])),
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              child: Text('${overallRate.toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ]),
        ),

        // ── Per-centre cards ─────────────────────────────
        ...centres.map((centre) {
          final m = _centreData[centre]?[month];
          final present  = m?['present']  ?? 0;
          final absent   = m?['absent']   ?? 0;
          final dropout  = m?['dropout']  ?? 0;
          final total    = m?['total']    ?? 0;
          final students = m?['students'] ?? 0;
          final rate     = _rate(centre, month);
          final zone     = _centreToZone[centre] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Centre header row
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: _rateColor(rate).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.location_city, color: _rateColor(rate), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(centre, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  Text('Zone: $zone', style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _rateColor(rate).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${rate.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _rateColor(rate))),
                ),
              ]),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                value: (rate / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation(_rateColor(rate)),
              )),
              const SizedBox(height: 12),

              // Stats row
              Row(children: [
                _statPill(Icons.check_circle, '$present', 'Present', const Color(0xFF10B981), isDark),
                const SizedBox(width: 8),
                _statPill(Icons.cancel, '$absent', 'Absent', const Color(0xFFF59E0B), isDark),
                const SizedBox(width: 8),
                _statPill(Icons.person_off, '$dropout', 'Dropout', const Color(0xFFEF4444), isDark),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('$students students', style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                  Text('$total sessions', style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                ]),
              ]),
            ]),
          );
        }),
      ],
    );
  }

  Widget _statPill(IconData icon, String value, String label, Color color, bool isDark) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text('$value $label', style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
    ]);
  }
}
