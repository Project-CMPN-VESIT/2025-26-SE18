import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Global key used by auth_provider to navigate to /reset-password on recovery event
final GlobalKey<NavigatorState> authNavigatorKey = GlobalKey<NavigatorState>();

class AppAuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, String>? _userProfile;
  String? _loginTime;
  bool _isLoading = true;

  Map<String, String>? get user => _userProfile;
  String? get loginTime => _loginTime;
  bool get isLoggedIn => _userProfile != null;
  bool get isLoading => _isLoading;
  String? get role => _userProfile?['role'];
  String? get uid => _supabase.auth.currentUser?.id;

  AppAuthProvider() {
    _init();
  }

  void _init() {
    // Listen to Supabase auth state changes
    _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final event   = data.event;

      // Password recovery — navigate to the reset-password screen
      if (event == AuthChangeEvent.passwordRecovery) {
        authNavigatorKey.currentState?.pushNamedAndRemoveUntil('/reset-password', (_) => false);
        return;
      }

      if (session != null) {
        await _loadProfile(session.user.id);
      } else {
        _userProfile = null;
        _loginTime = null;
      }
      _isLoading = false;
      notifyListeners();
    });

    // Handle the initial session (e.g. persisted session on app restart)
    final existingSession = _supabase.auth.currentSession;
    if (existingSession != null) {
      _loadProfile(existingSession.user.id).then((_) {
        _isLoading = false;
        notifyListeners();
      });
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfile(String uid) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      if (data != null) {
        _userProfile = {
          'email': data['email']?.toString() ?? '',
          'role': data['role']?.toString() ?? 'teacher',
          'name': data['name']?.toString() ?? '',
          'zone': data['zone']?.toString() ?? '',
          'centre': data['centre']?.toString() ?? '',
          'uid': uid,
        };
      } else {
        // Fallback: build profile from auth user metadata
        final authUser = _supabase.auth.currentUser!;
        final meta = authUser.userMetadata ?? {};
        _userProfile = {
          'email': authUser.email ?? '',
          'role': meta['role']?.toString() ?? 'teacher',
          'name': meta['name']?.toString() ??
              authUser.email?.split('@')[0] ??
              '',
          'zone': meta['zone']?.toString() ?? '',
          'centre': meta['centre']?.toString() ?? '',
          'uid': uid,
        };
      }

      final now = TimeOfDay.now();
      final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
      final period = now.period == DayPeriod.am ? 'AM' : 'PM';
      _loginTime =
          '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _userProfile = null;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (response.user == null) {
        return {'success': false, 'message': 'Login failed. Please try again.'};
      }

      await _loadProfile(response.user!.id);
      notifyListeners();

      return {'success': true, 'role': _userProfile?['role'] ?? 'teacher'};
    } on AuthException catch (e) {
      String message;
      switch (e.statusCode) {
        case '400':
          message = 'Invalid email or password.';
          break;
        case '422':
          message = 'Please enter a valid email address.';
          break;
        default:
          message = e.message.isNotEmpty
              ? e.message
              : 'Login failed. Please try again.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please check your internet connection.'
      };
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _userProfile = null;
    _loginTime = null;
    notifyListeners();
  }
}
