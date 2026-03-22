import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AppAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, String>? _userProfile;
  String? _loginTime;
  bool _isLoading = true;

  Map<String, String>? get user => _userProfile;
  String? get loginTime => _loginTime;
  bool get isLoggedIn => _userProfile != null;
  bool get isLoading => _isLoading;
  String? get role => _userProfile?['role'];
  String? get uid => _auth.currentUser?.uid;

  AppAuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await _loadProfile(firebaseUser.uid);
      } else {
        _userProfile = null;
        _loginTime = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _loadProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _userProfile = {
          'email': data['email']?.toString() ?? '',
          'role': data['role']?.toString() ?? 'teacher',
          'name': data['name']?.toString() ?? '',
          'zone': data['zone']?.toString() ?? '',
          'centre': data['centre']?.toString() ?? '',
          'uid': uid,
        };
      } else {
        // Fallback: use Firebase Auth display name
        final fbUser = _auth.currentUser!;
        _userProfile = {
          'email': fbUser.email ?? '',
          'role': 'teacher',
          'name': fbUser.displayName ?? fbUser.email?.split('@')[0] ?? '',
          'uid': uid,
        };
      }
      final now = TimeOfDay.now();
      final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
      final period = now.period == DayPeriod.am ? 'AM' : 'PM';
      _loginTime = '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _userProfile = null;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // 1) Validate against NGO User Directory Google Sheet via Cloud Function.
      final callable = FirebaseFunctions.instance.httpsCallable('sheetLogin');
      final sheetResult = await callable.call(<String, dynamic>{
        'email': email,
        'password': password,
      });

      final data = Map<String, dynamic>.from(sheetResult.data as Map);
      if (data['success'] != true) {
        final message = data['message']?.toString() ?? 'Login not allowed.';
        return {'success': false, 'message': message};
      }

      // 2) If sheet allows login, sign in with Firebase Auth.
      // The backend keeps Auth password in sync with the sheet password.
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3) Load Firestore profile (created/updated server-side) and set state.
      await _loadProfile(credential.user!.uid);
      notifyListeners();

      return {'success': true, 'role': _userProfile?['role'] ?? 'teacher'};
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'invalid-credential':
          message = 'Invalid credentials. Please try again.';
          break;
        default:
          message = e.message ?? 'Login failed. Please try again.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Connection error. Are the Firebase emulators running?'};
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _userProfile = null;
    _loginTime = null;
    notifyListeners();
  }
}
