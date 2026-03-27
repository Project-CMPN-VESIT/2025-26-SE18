import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/data_provider.dart';
import '../../layouts/teacher_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final data = context.watch<DataProvider>();
    final dateStr = DateFormat('MMM d, yyyy').format(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get leave notifications (approved/denied) and pending count
    final leaves = data.leaves;
    final approvedOrDenied = leaves.where((l) => l['status'] == 'approved' || l['status'] == 'denied').toList();
    final pending = leaves.where((l) => l['status'] == 'pending').toList();

    return TeacherLayout(
      child: Column(
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.primaryDark],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome, ${auth.user?['name'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('$dateStr · ${auth.loginTime ?? ''}', style: TextStyle(color: Colors.blue[200], fontSize: 14)),
                      ],
                    ),
                    Row(
                      children: [
                        _circleButton(theme.isDark ? Icons.light_mode : Icons.dark_mode, () => theme.toggleTheme()),
                        const SizedBox(width: 8),
                        _circleButton(Icons.logout, () { auth.logout(); }),
                      ],
                    ),
                  ],
                ),

              ],
            ),
          ),

          // Actions
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Announcements ────────────────────────────────
                  if (data.announcements.isNotEmpty) ...[
                    ...data.announcements.map((ann) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFBE123C)]), // Crimson
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: const Color(0xFFE11D48).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.campaign, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('ZONAL BROADCAST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                                    ]
                                  ),
                                  const SizedBox(height: 6),
                                  Text(ann['message'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15)),
                                  const SizedBox(height: 8),
                                  Text('— ${ann['authorName'] ?? 'Coordinator'}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontStyle: FontStyle.italic)),
                                ]
                              )
                            )
                          ]
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],

                  // ─── Leave Notifications ────────────────────────
                  if (approvedOrDenied.isNotEmpty || pending.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.notifications_active, size: 18, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text('Leave Updates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...leaves.map((l) {
                      final status = l['status']?.toString() ?? 'pending';
                      final isApproved = status == 'approved';
                      final isDenied = status == 'denied';
                      final isPending = status == 'pending';

                      final Color bgColor;
                      final Color borderColor;
                      final Color textColor;
                      final IconData icon;
                      final String statusLabel;

                      if (isApproved) {
                        bgColor = const Color(0xFFECFDF5);
                        borderColor = const Color(0xFF6EE7B7);
                        textColor = const Color(0xFF065F46);
                        icon = Icons.check_circle;
                        statusLabel = '✅ APPROVED';
                      } else if (isDenied) {
                        bgColor = const Color(0xFFFEF2F2);
                        borderColor = const Color(0xFFFCA5A5);
                        textColor = const Color(0xFF991B1B);
                        icon = Icons.cancel;
                        statusLabel = '❌ DENIED';
                      } else {
                        bgColor = const Color(0xFFFFFBEB);
                        borderColor = const Color(0xFFFDE68A);
                        textColor = const Color(0xFF92400E);
                        icon = Icons.hourglass_top;
                        statusLabel = '⏳ PENDING';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? (isApproved ? const Color(0xFF064E3B) : isDenied ? const Color(0xFF7F1D1D) : const Color(0xFF78350F)).withValues(alpha: 0.3) : bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, color: isApproved ? const Color(0xFF10B981) : isDenied ? const Color(0xFFEF4444) : const Color(0xFFF59E0B), size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text('${l['type'] ?? 'Leave'} — $statusLabel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : textColor))),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${l['from']} → ${l['to']} (${l['days']} day${(l['days'] ?? 1) > 1 ? 's' : ''})', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : textColor.withValues(alpha: 0.8))),
                                  if (isPending)
                                    Text('Awaiting coordinator approval', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? const Color(0xFF64748B) : textColor.withValues(alpha: 0.6))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // ─── My Students ──────────────────────────────
                  if (data.students.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.school, size: 18, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            Text('My Students', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.go('/teacher/students'),
                          child: const Text('View All', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: data.students.length > 5 ? 5 : data.students.length,
                        itemBuilder: (context, index) {
                          final s = data.students[index];
                          return Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(s['name'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(s['roll'] ?? '', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                const SizedBox(height: 4),
                                StatusBadge(label: s['class'] ?? 'N/A', variant: 'teacher'),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.1,
                    children: const [
                      ActionCard(to: '/teacher/attendance', icon: Icons.event_available, title: 'Mark Attendance', subtitle: "Today's Class", iconColor: Color(0xFF10B981)),
                      ActionCard(to: '/teacher/students', icon: Icons.group, title: 'Students', subtitle: 'View All', iconColor: Color(0xFF8B5CF6)),
                      ActionCard(to: '/teacher/diary', icon: Icons.menu_book, title: 'Diary Notes', subtitle: 'Class Journal', iconColor: Color(0xFFF59E0B)),
                      ActionCard(to: '/teacher/resources', icon: Icons.folder, title: 'Resources', subtitle: 'Teaching Aids', iconColor: Color(0xFF3B82F6)),
                      ActionCard(to: '/teacher/leave', icon: Icons.event_busy, title: 'Leave Request', subtitle: 'Apply Now', iconColor: Color(0xFFEF4444)),
                      ActionCard(to: '/teacher/exams', icon: Icons.school, title: 'Exam Results', subtitle: 'Manage Scores', iconColor: Color(0xFF14B8A6)),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _statBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label.toUpperCase(), style: TextStyle(color: Colors.blue[200], fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
