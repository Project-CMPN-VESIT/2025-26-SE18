import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/data_provider.dart';
import '../../layouts/admin_layout.dart';
import '../../widgets/app_widgets.dart';
import '../../theme/app_theme.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});
  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  String _filter = 'all';
  String _search = '';

  // ── Send password reset email to a user ──────────────────────
  Future<void> _sendResetEmail(BuildContext context, String email, String name) async {
    bool sending = false;
    bool sent    = false;
    String? err;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.lock_reset, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Send Reset Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          content: sent
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.mark_email_read, color: Color(0xFF10B981), size: 44),
                const SizedBox(height: 12),
                Text('Reset email sent to\n$email', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
              ])
            : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                RichText(text: TextSpan(
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  children: [
                    const TextSpan(text: 'This will send a password reset email to '),
                    TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const TextSpan(text: ' ('),
                    TextSpan(text: email, style: const TextStyle(color: AppTheme.primary)),
                    const TextSpan(text: ').'),
                  ],
                )),
                if (err != null) ...[
                  const SizedBox(height: 10),
                  Text(err!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
                ],
              ]),
          actions: sent
            ? [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)))]
            : [
                TextButton(onPressed: sending ? null : () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: sending ? null : () async {
                    set(() { sending = true; err = null; });
                    try {
                      await Supabase.instance.client.auth.resetPasswordForEmail(
                        email,
                        redirectTo: '${Uri.base.origin}/reset-password',
                      );
                      set(() { sent = true; sending = false; });
                    } on AuthException catch (e) {
                      set(() { err = e.message; sending = false; });
                    } catch (_) {
                      set(() { err = 'Something went wrong.'; sending = false; });
                    }
                  },
                  child: sending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Email'),
                ),
              ],
        ),
      ),
    );
  }

  // ── Admin: change own password ────────────────────────────────
  Future<void> _showAdminChangePassword(BuildContext context) async {
    final pwdCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool showPwd = false, showConfirm = false;
    bool loading = false, done = false;
    String? err;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.lock_person, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Change My Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          content: done
            ? const Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle, color: Color(0xFF10B981), size: 44),
                SizedBox(height: 10),
                Text('Password changed successfully!', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
              ])
            : Column(mainAxisSize: MainAxisSize.min, children: [
                _pwdField('New Password', pwdCtrl, showPwd, () => set(() => showPwd = !showPwd)),
                const SizedBox(height: 12),
                _pwdField('Confirm Password', confirmCtrl, showConfirm, () => set(() => showConfirm = !showConfirm)),
                if (err != null) ...[
                  const SizedBox(height: 10),
                  Text(err!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
                ],
              ]),
          actions: done
            ? [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)))]
            : [
                TextButton(onPressed: loading ? null : () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: loading ? null : () async {
                    final pwd     = pwdCtrl.text.trim();
                    final confirm = confirmCtrl.text.trim();
                    if (pwd.length < 8) { set(() => err = 'Min 8 characters.'); return; }
                    if (pwd != confirm) { set(() => err = 'Passwords do not match.'); return; }
                    set(() { loading = true; err = null; });
                    try {
                      await Supabase.instance.client.auth.updateUser(UserAttributes(password: pwd));
                      set(() { done = true; loading = false; });
                    } on AuthException catch (e) {
                      set(() { err = e.message; loading = false; });
                    } catch (_) {
                      set(() { err = 'Something went wrong.'; loading = false; });
                    }
                  },
                  child: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Update'),
                ),
              ],
        ),
      ),
    );
    pwdCtrl.dispose();
    confirmCtrl.dispose();
  }

  static Widget _pwdField(String label, TextEditingController ctrl, bool show, VoidCallback toggle) =>
    TextField(
      controller: ctrl,
      obscureText: !show,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF94A3B8)),
        suffixIcon: IconButton(icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF94A3B8), size: 18), onPressed: toggle),
        filled: true, fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tCount = data.teachers.length;
    final cCount = data.coordinators.length;
    final sCount = data.students.length;
    final aCount = tCount + cCount + sCount;

    String getTabLabel(String f) {
      if (f == 'teacher') return 'Teachers ($tCount)';
      if (f == 'coordinator') return 'Coordinators ($cCount)';
      if (f == 'student') return 'Students ($sCount)';
      return 'All ($aCount)';
    }

    List<Map<String, dynamic>> allUsers = [];
    if (_filter == 'all' || _filter == 'teacher') {
      allUsers.addAll(data.teachers.map((t) => {...t, 'role': 'teacher'}));
    }
    if (_filter == 'all' || _filter == 'coordinator') {
      allUsers.addAll(data.coordinators.map((c) => {...c, 'role': 'coordinator'}));
    }
    if (_filter == 'all' || _filter == 'student') {
      allUsers.addAll(data.students.map((s) => {...s, 'role': 'student'}));
    }
    if (_search.isNotEmpty) {
      allUsers = allUsers.where((u) => u['name'].toString().toLowerCase().contains(_search.toLowerCase())).toList();
    }

    return AdminLayout(
      child: Column(children: [
        AppHeader(
          title: 'User Management',
          backTo: '/admin',
          rightActions: [
            IconButton(
              icon: const Icon(Icons.lock_person, color: AppTheme.primary),
              tooltip: 'Change My Password',
              onPressed: () => _showAdminChangePassword(context),
            ),
          ],
        ),
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(hintText: 'Search users...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
            filled: true, fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
          ),
        )),
        // Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(
            children: ['all', 'teacher', 'coordinator', 'student'].map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChipWidget(label: getTabLabel(f), active: _filter == f, onTap: () => setState(() => _filter = f)),
            )).toList(),
          )),
        ),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: allUsers.length,
          itemBuilder: (_, i) {
            final u = allUsers[i];
            final role    = u['role']?.toString() ?? '';
            final email   = u['email']?.toString() ?? '';
            final name    = u['name']?.toString() ?? '?';
            final canReset = role == 'teacher' || role == 'coordinator';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
              ),
              child: Row(children: [
                Container(width: 40, height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withValues(alpha: 0.1)),
                  child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  Text(email.isNotEmpty ? email : (u['roll']?.toString() ?? ''), style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  StatusBadge(label: role, variant: role),
                  const SizedBox(height: 4),
                  StatusBadge(label: u['status']?.toString() ?? 'active', variant: u['status']?.toString() ?? 'active'),
                  if (canReset) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _sendResetEmail(context, email, name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: const [
                          Icon(Icons.lock_reset, size: 11, color: AppTheme.primary),
                          SizedBox(width: 3),
                          Text('Reset Pwd', style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ],
                ]),
              ]),
            );
          },
        )),
      ]),
    );
  }
}
