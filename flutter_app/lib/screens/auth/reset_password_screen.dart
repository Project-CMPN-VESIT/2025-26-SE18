import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

/// Shown when user clicks the password-reset link from their email.
/// Supabase redirects to /reset-password with a recovery token in the URL hash.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  bool _showPwd        = false;
  bool _showConfirm    = false;
  bool _loading        = false;
  bool _done           = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pwd     = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (pwd.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (pwd != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pwd),
      );
      if (mounted) setState(() { _loading = false; _done = true; });
    } on AuthException catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.message; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Something went wrong. Try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageShell(
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC), Color(0xFFDBEAFE)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: const Icon(Icons.lock_reset, color: AppTheme.primary, size: 48),
                    ),
                    const SizedBox(height: 24),
                    const Text('Set New Password', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    const Text('Choose a strong password for your account', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    const SizedBox(height: 36),

                    // Card
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.07), blurRadius: 28, offset: const Offset(0, 12))],
                      ),
                      child: _done ? _buildSuccessView() : _buildFormView(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() => Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 56),
    const SizedBox(height: 16),
    const Text('Password Updated!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
    const SizedBox(height: 8),
    const Text('Your password has been changed successfully. You can now sign in with your new password.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
    const SizedBox(height: 24),
    SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        onPressed: () => context.go('/login'),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: const Text('Back to Login', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    ),
  ]);

  Widget _buildFormView() => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    // Error banner
    if (_error != null) ...[
      Container(
        width: double.infinity, padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFECACA))),
        child: Row(children: [
          const Icon(Icons.error, size: 16, color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13))),
        ]),
      ),
    ],

    // New Password
    const Text('New Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
    const SizedBox(height: 8),
    TextField(
      controller: _passwordCtrl,
      obscureText: !_showPwd,
      onChanged: (_) => setState(() => _error = null),
      decoration: InputDecoration(
        hintText: 'At least 8 characters',
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF94A3B8)),
        suffixIcon: IconButton(
          icon: Icon(_showPwd ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF94A3B8), size: 20),
          onPressed: () => setState(() => _showPwd = !_showPwd),
        ),
        filled: true, fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
      ),
    ),
    const SizedBox(height: 16),

    // Confirm Password
    const Text('Confirm New Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
    const SizedBox(height: 8),
    TextField(
      controller: _confirmCtrl,
      obscureText: !_showConfirm,
      onChanged: (_) => setState(() => _error = null),
      decoration: InputDecoration(
        hintText: 'Re-enter new password',
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF94A3B8)),
        suffixIcon: IconButton(
          icon: Icon(_showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF94A3B8), size: 20),
          onPressed: () => setState(() => _showConfirm = !_showConfirm),
        ),
        filled: true, fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
      ),
    ),
    const SizedBox(height: 28),

    // Submit
    SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : const Text('Update Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    ),
    const SizedBox(height: 12),
    Center(
      child: TextButton(
        onPressed: () => context.go('/login'),
        child: const Text('Back to Login', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
      ),
    ),
  ]);
}
