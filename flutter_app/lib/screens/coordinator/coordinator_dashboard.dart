import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/data_provider.dart';
import '../../layouts/coordinator_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class CoordinatorDashboard extends StatelessWidget {
  const CoordinatorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final data = context.watch<DataProvider>();
    final dateStr = DateFormat('MMM d, yyyy').format(DateTime.now());
    final leaves = data.leaves;
    final pendingLeaves = leaves.where((l) => l['status'] == 'pending').length;

    // ─── Computational Algorithms for Focus List ────────────────
    final List<Map<String, dynamic>> atRiskStudents = [];
    for (var s in data.students) {
      final total = s['totalClasses'] as int? ?? 0;
      final present = s['presentCount'] as int? ?? 0;
      final consAbs = s['consecutiveAbsences'] as int? ?? 0;
      
      String? flag;
      if (consAbs >= 3) {
        flag = '⚠️ $consAbs Continuous Absences';
      } else if (total >= 5) {
        final double percentage = present / total;
        if (percentage <= 0.50) {
          final pStr = (percentage * 100).toStringAsFixed(0);
          flag = '📉 Critically Low ($pStr%)';
        }
      }
      
      if (flag != null) {
        atRiskStudents.add({
          ...s,
          'flag': flag,
          'isCritical': consAbs >= 3,
        });
      }
    }

    return CoordinatorLayout(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.primary, AppTheme.primaryDark])),
            padding: const EdgeInsets.fromLTRB(20, 36, 20, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$dateStr · ${auth.loginTime ?? ''}', style: TextStyle(color: Colors.blue[200], fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('Welcome, ${auth.user?['name'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ]),
                    Row(children: [
                      _circleBtn(theme.isDark ? Icons.light_mode : Icons.dark_mode, () => theme.toggleTheme()),
                      const SizedBox(width: 8),
                      _circleBtn(Icons.logout, () => auth.logout()),
                    ]),
                  ],
                ),
                const SizedBox(height: 12),
                Row(children: [
                  _miniStat('${data.centres.length}', 'Centres'),
                  const SizedBox(width: 8),
                  _miniStat('${data.teachers.length}', 'Teachers'),
                  const SizedBox(width: 8),
                  _miniStat('${data.students.length}', 'Students'),
                ]),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B))),
                const SizedBox(height: 12),
                GridView.count(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.25, children: [
                  const ActionCard(to: '/coordinator/manage', icon: Icons.manage_accounts, title: 'Manage Staff', subtitle: 'Teachers & Students', iconColor: Color(0xFF8B5CF6)),
                  const ActionCard(to: '/coordinator/centres', icon: Icons.map, title: 'Centres', subtitle: 'Your Region', iconColor: Color(0xFF3B82F6)),
                  const ActionCard(to: '/coordinator/analytics', icon: Icons.analytics, title: 'Analytics', subtitle: 'Performance Data', iconColor: Color(0xFF14B8A6)),
                  ActionCard(to: '/coordinator/leaves', icon: Icons.event_busy, title: 'Leave Approvals', subtitle: 'Pending Requests', iconColor: const Color(0xFFF59E0B), badgeCount: pendingLeaves),
                ]),
                if (pendingLeaves > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFDE68A))),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.warning, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('$pendingLeaves Pending Approval${pendingLeaves > 1 ? 's' : ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                        const SizedBox(height: 2),
                        const Text('Teachers awaiting leave approval', style: TextStyle(fontSize: 12, color: Color(0xFFD97706))),
                        const SizedBox(height: 8),
                        GestureDetector(onTap: () => context.go('/coordinator/leaves'), child: const Text('Review Now →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary))),
                      ])),
                    ]),
                  ),
                ],
                const SizedBox(height: 16),
                _broadcastAction(context, data, auth),
                
                // ─── FOCUS LIST (Dropout Prevention) ────────────────
                const SizedBox(height: 16),
                _focusListAction(context, atRiskStudents, Theme.of(context).brightness == Brightness.dark),
                
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)), child: Icon(icon, color: Colors.white, size: 20)),
  );

  Widget _miniStat(String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label.toUpperCase(), style: TextStyle(color: Colors.blue[200], fontSize: 9, fontWeight: FontWeight.w600)),
      ]),
    ),
  );

  Widget _broadcastAction(BuildContext context, DataProvider data, AppAuthProvider auth) {
    return GestureDetector(
      onTap: () => _showBroadcastDialog(context, data, auth),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFBE123C)]), // Crisp Red Gradient
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: const Color(0xFFE11D48).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.campaign, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Broadcast Announcement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Send instant alerts to all zone teachers', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ]
            )),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        )
      )
    );
  }

  Widget _focusListAction(BuildContext context, List<Map<String, dynamic>> students, bool isDark) {
    return GestureDetector(
      onTap: () => _showFocusListSheet(context, students, isDark),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)]), // Deep Purple Pattern
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: const Color(0xFF6D28D9).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.track_changes, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Focus List', style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 17)),
                Text('Identify & prevent student dropouts', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ]
            )),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        )
      )
    );
  }

  void _showFocusListSheet(BuildContext context, List<Map<String, dynamic>> students, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48), size: 26),
                const SizedBox(width: 8),
                Text('Needs Intervention', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Students statistically at risk of dropping out', style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
            const SizedBox(height: 16),
            if (students.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 48),
                    const SizedBox(height: 16),
                    Text('0 Dropout Risks Detected', style: TextStyle(color: isDark ? const Color(0xFF34D399) : const Color(0xFF166534), fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('All active students are attending classes regularly!', style: TextStyle(color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46), fontSize: 13), textAlign: TextAlign.center),
                  ],
                ),
              )
            else
              Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final s = students[index];
                  final isCrit = s['isCritical'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isCrit ? const Color(0xFFFCA5A5) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                      boxShadow: [BoxShadow(color: (isCrit ? const Color(0xFFEF4444) : Colors.black).withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: isCrit ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC), shape: BoxShape.circle),
                          child: Icon(Icons.person, color: isCrit ? const Color(0xFFEF4444) : AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['name']?.toString() ?? 'Unknown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text(s['centre']?.toString() ?? '', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCrit ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: isCrit ? const Color(0xFFFCA5A5) : const Color(0xFFFDE68A)),
                                ),
                                child: Text(s['flag']?.toString() ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCrit ? const Color(0xFFB91C1C) : const Color(0xFFB45309))),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.phone, color: AppTheme.primary, size: 20)
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Calling parent of ${s['name']}...")));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context, DataProvider data, AppAuthProvider auth) {
    final textController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(children: [Icon(Icons.campaign, color: Color(0xFFE11D48)), SizedBox(width: 8), Text('Broadcast Message')]),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: textController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Type your urgent message or alert here...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white),
                  onPressed: isSaving ? null : () async {
                    if (textController.text.trim().isEmpty) return;
                    setState(() => isSaving = true);
                    try {
                      final zone = (auth.user?['zone'] ?? '').toString();
                      final author = (auth.user?['name'] ?? 'Coordinator').toString();
                      final uid = auth.user!['uid'].toString();
                      await data.addAnnouncement(textController.text.trim(), zone, uid, author);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement successfully broadcasted!')));
                      }
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error computing broadcast: $e")));
                    } finally {
                      setState(() => isSaving = false);
                    }
                  },
                  icon: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send),
                  label: Text(isSaving ? 'Sending...' : 'Send Broadcast'),
                ),
              ],
            );
          }
        );
      }
    );
  }
}
