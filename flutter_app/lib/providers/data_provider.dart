import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class DataProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Local cache populated by Firestore streams
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _coordinators = [];
  List<Map<String, dynamic>> _leaves = [];
  List<Map<String, dynamic>> _zones = [];
  List<Map<String, dynamic>> _centres = [];
  List<Map<String, dynamic>> _examResults = [];
  List<Map<String, dynamic>> _diaryEntries = [];
  List<Map<String, dynamic>> _resources = [];
  List<Map<String, dynamic>> _announcements = [];

  bool _isLoading = true;
  bool _initialized = false;

  // Stream subscriptions
  final List<StreamSubscription> _subscriptions = [];

  // Getters
  List<Map<String, dynamic>> get students => _students;
  List<Map<String, dynamic>> get teachers => _teachers;
  List<Map<String, dynamic>> get coordinators => _coordinators;
  List<Map<String, dynamic>> get leaves => _leaves;
  List<Map<String, dynamic>> get zones => _zones;
  List<Map<String, dynamic>> get centres => _centres;
  List<Map<String, dynamic>> get examResults => _examResults;
  List<Map<String, dynamic>> get diaryEntries => _diaryEntries;
  List<Map<String, dynamic>> get resources => _resources;
  List<Map<String, dynamic>> get announcements => _announcements;
  bool get isLoading => _isLoading;

  /// Initialize Firestore listeners scoped by role.
  /// Call this after login with the user's uid, role, and zone.
  void init(String uid, String role, String? zone, String? centre) {
    if (_initialized) return;
    _initialized = true;
    _isLoading = true;

    // Track how many streams have emitted their first value
    int streamsReady = 0;
    const totalStreams = 10;
    void onStreamReady() {
      streamsReady++;
      if (streamsReady >= totalStreams) {
        _isLoading = false;
      }
      notifyListeners();
    }

    // ─── Students ──────────────────────────────────────────────────
    Query studentsQuery = _db.collection('students');
    final effectiveZone = (zone != null && zone.isNotEmpty) ? zone : null;
    final effectiveCentre = (centre != null && centre.isNotEmpty) ? centre : null;

    if (role == 'teacher' && effectiveZone != null) {
      studentsQuery = studentsQuery.where('zone', isEqualTo: effectiveZone);
      if (effectiveCentre != null) {
        studentsQuery = studentsQuery.where('centre', isEqualTo: effectiveCentre);
      }
      // Only see students assigned to this teacher
      studentsQuery = studentsQuery.where('teacherId', isEqualTo: uid);
    } else if (role == 'coordinator' && effectiveZone != null) {
      studentsQuery = studentsQuery.where('zone', isEqualTo: effectiveZone);
    }
    _subscriptions.add(studentsQuery.snapshots().listen((snap) {
      _students = snap.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
      onStreamReady();
    }));

    // ─── Teachers (from users collection, role=teacher) ────────────
    Query teachersQuery = _db.collection('users').where('role', isEqualTo: 'teacher');
    if (role == 'coordinator' && zone != null) {
      teachersQuery = teachersQuery.where('zone', isEqualTo: zone);
    }
    _subscriptions.add(teachersQuery.snapshots().listen((snap) {
      _teachers = snap.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
      onStreamReady();
    }));

    // ─── Coordinators (from users collection, role=coordinator) ────
    Query coordsQuery = _db.collection('users').where('role', isEqualTo: 'coordinator');
    _subscriptions.add(coordsQuery.snapshots().listen((snap) {
      _coordinators = snap.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
      onStreamReady();
    }));

    // ─── Leaves ────────────────────────────────────────────────────
    Query leavesQuery = _db.collection('leaves');
    if (role == 'teacher') {
      leavesQuery = leavesQuery.where('userId', isEqualTo: uid);
    } else if (role == 'coordinator' && zone != null) {
      leavesQuery = leavesQuery.where('zone', isEqualTo: zone);
    }
    _subscriptions.add(leavesQuery.snapshots().listen((snap) {
      _leaves = snap.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
      onStreamReady();
    }));

    // ─── Zones ─────────────────────────────────────────────────────
    _subscriptions.add(_db.collection('zones').snapshots().listen((snap) {
      _zones = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      onStreamReady();
    }));

    // ─── Centres ───────────────────────────────────────────────────
    Query centresQuery = _db.collection('centres');
    if (role == 'coordinator' && effectiveZone != null) {
      centresQuery = centresQuery.where('zone', isEqualTo: effectiveZone);
    }
    _subscriptions.add(centresQuery.snapshots().listen((snap) {
      _centres = snap.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
      onStreamReady();
    }));

    // ─── Exam Results ──────────────────────────────────────────────
    Query examsQuery = _db.collection('examResults');
    if (role == 'teacher') {
      examsQuery = examsQuery.where('teacherId', isEqualTo: uid);
    } else if (role == 'coordinator' && effectiveZone != null) {
      examsQuery = examsQuery.where('zone', isEqualTo: effectiveZone);
    }
    _subscriptions.add(examsQuery.snapshots().listen((snap) {
      _examResults = snap.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
      onStreamReady();
    }));

    // ─── Diary Entries ─────────────────────────────────────────────
    Query diaryQuery = _db.collection('diaryEntries');
    if (role == 'teacher') {
      diaryQuery = diaryQuery.where('teacherId', isEqualTo: uid);
    } else if (role == 'coordinator' && zone != null) {
      diaryQuery = diaryQuery.where('zone', isEqualTo: zone);
    }
    _subscriptions.add(diaryQuery.snapshots().listen((snap) {
      _diaryEntries = snap.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
      onStreamReady();
    }));

    // ─── Resources ─────────────────────────────────────────────────
    Query resourcesQuery = _db.collection('resources');
    if (role == 'teacher') {
      resourcesQuery = resourcesQuery.where('teacherId', isEqualTo: uid);
    }
    _subscriptions.add(resourcesQuery.snapshots().listen((snap) {
      _resources = snap.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
      onStreamReady();
    }));

    // ─── Announcements ────────────────────────────────────────────
    Query announcementsQuery = _db.collection('announcements');
    if (role == 'teacher' || role == 'coordinator') {
      if (effectiveZone != null) announcementsQuery = announcementsQuery.where('zone', isEqualTo: effectiveZone);
    }
    // Limit to 5 most recent
    announcementsQuery = announcementsQuery.orderBy('createdAt', descending: true).limit(5);
    _subscriptions.add(announcementsQuery.snapshots().listen((snap) {
      _announcements = snap.docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();
      onStreamReady();
    }));
  }

  // ─── CRUD Methods ──────────────────────────────────────────────

  Future<void> addStudent(Map<String, dynamic> student) async {
    await _db.collection('students').add({
      ...student,
      'status': 'active',
      'attendance': '0%',
      'teacherId': student['teacherId'] ?? '',
      'zone': student['zone'] ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addTeacher(Map<String, dynamic> teacher) async {
    final callable = _functions.httpsCallable('createUser');
    await callable.call(<String, dynamic>{
      'email': teacher['email'],
      'password': teacher['password'],
      'name': teacher['name'],
      'role': 'teacher',
      'phone': teacher['phone'] ?? '',
      'zone': teacher['zone'] ?? '',
      'centre': teacher['centre'] ?? '',
    });
  }

  Future<void> addCoordinator(Map<String, dynamic> coordinator) async {
    final callable = _functions.httpsCallable('createUser');
    await callable.call(<String, dynamic>{
      'email': coordinator['email'],
      'password': coordinator['password'],
      'name': coordinator['name'],
      'role': 'coordinator',
      'phone': coordinator['phone'] ?? '',
      'zone': coordinator['zone'] ?? '',
    });
  }

  Future<void> addZone(Map<String, dynamic> zone) async {
    await _db.collection('zones').add({
      ...zone,
      'centres': 0,
      'teachers': 0,
      'students': 0,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addCentre(Map<String, dynamic> centre) async {
    await _db.collection('centres').add({
      ...centre,
      'teachers': 0,
      'students': 0,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update zone's centre count if zoneId is provided
    if (centre['zoneId'] != null) {
      await _db.collection('zones').doc(centre['zoneId']).update({
        'centres': FieldValue.increment(1),
      });
    }
  }

  Future<void> addLeave(Map<String, dynamic> leave) async {
    await _db.collection('leaves').add({
      ...leave,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateLeave(String id, Map<String, dynamic> data) async {
    await _db.collection('leaves').doc(id).update(data);
  }

  Future<void> updateStudent(String id, Map<String, dynamic> data) async {
    await _db.collection('students').doc(id).update(data);
  }

  Future<void> removeStudent(String id) async {
    await _db.collection('students').doc(id).delete();
  }

  Future<void> removeTeacher(String id) async {
    await _db.collection('users').doc(id).delete();
  }

  Future<void> addDiaryEntry(Map<String, dynamic> entry) async {
    await _db.collection('diaryEntries').add({
      ...entry,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDiaryEntry(String id, Map<String, dynamic> data) async {
    await _db.collection('diaryEntries').doc(id).update(data);
  }

  Future<void> deleteDiaryEntry(String id) async {
    await _db.collection('diaryEntries').doc(id).delete();
  }

  Future<void> addResource(Map<String, dynamic> resource) async {
    await _db.collection('resources').add({
      ...resource,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addAttendance(Map<String, dynamic> record) async {
    await _db.collection('attendance').add({
      ...record,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // Update Student Global Stats & Consecutive Absences Trigger
    final studentId = record['studentId'];
    final status = record['status']; 
    
    if (studentId != null && studentId.toString().isNotEmpty) {
      if (status == 'present') {
        await _db.collection('students').doc(studentId).set({
          'presentCount': FieldValue.increment(1),
          'totalClasses': FieldValue.increment(1),
          'consecutiveAbsences': 0,
        }, SetOptions(merge: true));
      } else if (status == 'absent' || status == 'dropout') {
        await _db.collection('students').doc(studentId).set({
          'absentCount': FieldValue.increment(1),
          'totalClasses': FieldValue.increment(1),
          'consecutiveAbsences': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
    }
  }

  Future<void> addExamResult(Map<String, dynamic> exam) async {
    await _db.collection('examResults').add({
      ...exam,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── ANNOUNCEMENTS ──────────────────────────────────────────────

  Future<void> addAnnouncement(String message, String zone, String authorId, String authorName) async {
    try {
      await _db.collection('announcements').add({
        'message': message,
        'zone': zone,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Error creating announcement: \$e");
      rethrow;
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      await _db.collection('announcements').doc(id).delete();
    } catch (e) {
      debugPrint("Error deleting announcement: \$e");
      rethrow;
    }
  }

  /// Sync users from Google Sheet → Firebase Auth + Firestore
  Future<Map<String, dynamic>> syncUsersFromSheet() async {
    try {
      final result = await _functions.httpsCallable('syncUsersFromSheet').call({});
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      return {'created': 0, 'skipped': 0, 'errors': [e.toString()], 'message': 'Error: $e'};
    }
  }

  /// Force manual sync of students from Google Sheet to Firestore
  Future<Map<String, dynamic>> syncStudentsFromSheet({String? zone, String? centre}) async {
    try {
      final callable = _functions.httpsCallable('onStudentCreated');
      final result = await callable.call({
        'action': 'forceSync',
        'zone': zone,
        'centre': centre
      });
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      debugPrint('Error syncing students from sheet: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Fetch students from Google Sheets via Cloud Function
  Future<List<Map<String, dynamic>>> fetchStudentsFromSheet({String? zone, String? centre}) async {
    try {
      final result = await _functions.httpsCallable('getStudentsFromSheet').call({
        'zone': zone ?? '',
        'centre': centre ?? '',
      });
      final data = result.data as Map<String, dynamic>;
      final students = (data['students'] as List<dynamic>?)
          ?.map((s) => Map<String, dynamic>.from(s as Map))
          .toList() ?? [];
      return students;
    } catch (e) {
      debugPrint('Error fetching students from sheet: $e');
      return [];
    }
  }

  /// Fetch attendance data from Google Sheets for a specific zone-centre
  Future<Map<String, dynamic>> fetchAttendanceFromSheet(String zone, String centre) async {
    try {
      final result = await _functions.httpsCallable('getAttendanceFromSheet').call({
        'zone': zone,
        'centre': centre,
      });
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      debugPrint('Error fetching attendance from sheet: $e');
      return {'headers': [], 'students': []};
    }
  }

  /// Reset state on logout
  void reset() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _students = [];
    _teachers = [];
    _coordinators = [];
    _leaves = [];
    _zones = [];
    _centres = [];
    _examResults = [];
    _diaryEntries = [];
    _resources = [];
    _isLoading = true;
    _initialized = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
