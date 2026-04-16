import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DataProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Local cache (Supabase uses polling/realtime channels instead of snapshots)
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

  // Realtime channel subscriptions
  RealtimeChannel? _realtimeChannel;

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

  /// Initialize data — call after login with the user's uid, role, zone, centre.
  Future<void> init(
      String uid, String role, String? zone, String? centre) async {
    if (_initialized) return;
    _initialized = true;
    _isLoading = true;
    notifyListeners();

    await _fetchAll(uid, role, zone, centre);
    _subscribeRealtime(uid, role, zone, centre);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchAll(
      String uid, String role, String? zone, String? centre) async {
    await Future.wait([
      _fetchStudents(uid, role, zone, centre),
      _fetchTeachers(role, zone),
      _fetchCoordinators(),
      _fetchLeaves(uid, role, zone),
      _fetchZones(),
      _fetchCentres(role, zone),
      _fetchExamResults(uid, role, zone),
      _fetchDiaryEntries(uid, role, zone),
      _fetchResources(uid, role),
      _fetchAnnouncements(role, zone),
    ]);
  }

  // ─── Fetch Helpers ────────────────────────────────────────────

  Future<void> _fetchStudents(
      String uid, String role, String? zone, String? centre) async {
    try {
      var query = _supabase.from('students').select();
      if (role == 'teacher' && centre != null && centre.isNotEmpty) {
        query = query.eq('centre', centre);
      } else if (role == 'coordinator' && zone != null && zone.isNotEmpty) {
        query = query.eq('zone', zone);
      }
      final data = await query;
      _students = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('DataProvider: fetchStudents error: $e');
    }
  }

  Future<void> _fetchTeachers(String role, String? zone) async {
    try {
      var query = _supabase.from('profiles').select().eq('role', 'teacher');
      if (role == 'coordinator' && zone != null && zone.isNotEmpty) {
        query = query.eq('zone', zone);
      }
      final data = await query;
      _teachers = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('DataProvider: fetchTeachers error: $e');
    }
  }

  Future<void> _fetchCoordinators() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'coordinator');
      _coordinators = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('DataProvider: fetchCoordinators error: $e');
    }
  }

  Future<void> _fetchLeaves(
      String uid, String role, String? zone) async {
    try {
      var query = _supabase.from('leaves').select();
      if (role == 'teacher') {
        query = query.eq('user_id', uid);
      } else if (role == 'coordinator' && zone != null && zone.isNotEmpty) {
        query = query.eq('zone', zone);
      }
      final data = await query;
      _leaves = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('DataProvider: fetchLeaves error: $e');
    }
  }

  Future<void> _fetchZones() async {
    try {
      final data = await _supabase.from('zones').select();
      _zones = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('DataProvider: fetchZones error: $e');
    }
  }

  Future<void> _fetchCentres(String role, String? zone) async {
    try {
      var query = _supabase.from('centres').select();
      if (role == 'coordinator' && zone != null && zone.isNotEmpty) {
        query = query.eq('zone', zone);
      }
      final data = await query;
      _centres = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('DataProvider: fetchCentres error: $e');
    }
  }

  Future<void> _fetchExamResults(
      String uid, String role, String? zone) async {
    try {
      var query = _supabase.from('exam_results').select();
      if (role == 'teacher') {
        query = query.eq('teacher_id', uid);
      } else if (role == 'coordinator' && zone != null && zone.isNotEmpty) {
        query = query.eq('zone', zone);
      }
      final data = await query;
      _examResults = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('DataProvider: fetchExamResults error: $e');
    }
  }

  Future<void> _fetchDiaryEntries(
      String uid, String role, String? zone) async {
    try {
      var query = _supabase.from('diary_entries').select();
      if (role == 'teacher') {
        query = query.eq('teacher_id', uid);
      } else if (role == 'coordinator' && zone != null && zone.isNotEmpty) {
        query = query.eq('zone', zone);
      }
      final data = await query;
      _diaryEntries = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('DataProvider: fetchDiaryEntries error: $e');
    }
  }

  Future<void> _fetchResources(String uid, String role) async {
    try {
      var query = _supabase.from('resources').select();
      if (role == 'teacher') {
        query = query.eq('teacher_id', uid);
      }
      final data = await query;
      _resources = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('DataProvider: fetchResources error: $e');
    }
  }

  Future<void> _fetchAnnouncements(String role, String? zone) async {
    try {
      var query = _supabase.from('announcements').select();
      
      if ((role == 'teacher' || role == 'coordinator') &&
          zone != null &&
          zone.isNotEmpty) {
        query = query.or('zone.eq.$zone,zone.is.null');
      }
      
      final data = await query.order('created_at', ascending: false).limit(5);
      _announcements = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('DataProvider: fetchAnnouncements error: $e');
    }
  }

  // ─── Realtime Subscription ────────────────────────────────────
  /// Subscribe to Supabase Realtime for live updates.
  /// NOTE: Enable Realtime on tables in Supabase Dashboard → Database → Replication.
  void _subscribeRealtime(
      String uid, String role, String? zone, String? centre) {
    _realtimeChannel = _supabase
        .channel('db_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'students',
          callback: (_) => _fetchStudents(uid, role, zone, centre)
              .then((_) => notifyListeners()),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'leaves',
          callback: (_) =>
              _fetchLeaves(uid, role, zone).then((_) => notifyListeners()),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'announcements',
          callback: (_) =>
              _fetchAnnouncements(role, zone).then((_) => notifyListeners()),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'diary_entries',
          callback: (_) =>
              _fetchDiaryEntries(uid, role, zone).then((_) => notifyListeners()),
        )
        .subscribe();
  }

  // ─── CRUD Methods ─────────────────────────────────────────────

  Future<void> addStudent(Map<String, dynamic> student) async {
    // 1. Encrypt Aadhaar if present via new SQL RPC
    String? encryptedAadhaar;
    if (student['aadhaar'] != null && student['aadhaar'].toString().isNotEmpty) {
      try {
        final res = await _supabase.rpc('encrypt_aadhaar', params: {'aadhaar': student['aadhaar'].toString()});
        encryptedAadhaar = res.toString();
      } catch (e) {
        debugPrint('Encryption error: $e');
      }
    }

    // 2. Insert into students table with correct schema keys
    await _supabase.from('students').insert({
      'name': student['name'],
      'roll': student['roll'],
      'class': student['class'],
      'centre': student['centre'],
      'zone': student['zone'],
      'contact': student['contact'],
      'aadhaar_encrypted': encryptedAadhaar,
      'status': 'active',
      'teacher_id': _supabase.auth.currentUser?.id,
    });

    final uid = _supabase.auth.currentUser?.id ?? '';
    final role = 'teacher';
    await _fetchStudents(uid, role, student['zone'], student['centre']);
    notifyListeners();
  }

  Future<void> addTeacher(Map<String, dynamic> teacher) async {
    try {
      // Call our NEW Supabase Edge Function instead of Firebase
      final response = await _supabase.functions.invoke(
        'create-user',
        headers: {
          'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken}',
        },
        body: {
          'email': teacher['email'],
          'password': teacher['password'],
          'name': teacher['name'],
          'role': 'teacher',
          'phone': teacher['phone'] ?? '',
          'zone': teacher['zone'] ?? '',
          'centre': teacher['centre'] ?? '',
        },
      );

      if (response.status != 200) {
        if (response.status == 401) {
          throw Exception('Identity Error (401): Ensure you have deployed the "create-user" Edge Function using "supabase functions deploy create-user" and are logged in correctly.');
        }
        throw Exception('Failed to create teacher: ${response.data}');
      }

      await _fetchTeachers('admin', null);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating teacher: $e');
      rethrow;
    }
  }

  Future<void> addCoordinator(Map<String, dynamic> coordinator) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-user',
        headers: {
          'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken}',
        },
        body: {
          'email': coordinator['email'],
          'password': coordinator['password'],
          'name': coordinator['name'],
          'role': 'coordinator',
          'phone': coordinator['phone'] ?? '',
          'zone': coordinator['zone'] ?? '',
        },
      );

      if (response.status != 200) {
        if (response.status == 401) {
          throw Exception('Identity Error (401): Ensure you have deployed the "create-user" Edge Function using "npx supabase functions deploy create-user" and have logged in freshly.');
        }
        throw Exception('Failed to create coordinator: ${response.data}');
      }

      await _fetchCoordinators();
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating coordinator: $e');
      rethrow;
    }
  }

  Future<void> addZone(Map<String, dynamic> zone) async {
    await _supabase.from('zones').insert({
      ...zone,
      'centres': 0,
      'teachers': 0,
      'students': 0,
      'status': 'active',
    });
    await _fetchZones();
    notifyListeners();
  }

  Future<void> addCentre(Map<String, dynamic> centre) async {
    await _supabase.from('centres').insert({
      ...centre,
      'teachers': 0,
      'students': 0,
      'status': 'active',
    });

    // Update zone's centre count
    if (centre['zone'] != null) {
      await _supabase.rpc('increment_zone_centres',
          params: {'zone_name': centre['zone']});
    }
    await _fetchCentres('admin', null);
    notifyListeners();
  }

  Future<void> addLeave(Map<String, dynamic> leave) async {
    final uid = _supabase.auth.currentUser?.id;
    await _supabase.from('leaves').insert({
      'user_id': uid,
      'name': leave['name'],
      'role': leave['role'],
      'type': leave['type'],
      'from_date': leave['fromDate'],
      'to_date': leave['toDate'],
      'days': leave['days'],
      'reason': leave['reason'],
      'zone': leave['zone'],
      'status': 'pending',
    });
    await _fetchLeaves(uid ?? '', 'teacher', leave['zone']);
    notifyListeners();
  }

  Future<void> updateLeave(String id, Map<String, dynamic> data) async {
    // Map camelCase to snake_case if necessary
    final mapped = <String, dynamic>{};
    if (data.containsKey('status')) mapped['status'] = data['status'];
    if (data.containsKey('reason')) mapped['reason'] = data['reason'];

    await _supabase.from('leaves').update(mapped).eq('id', id);
    final uid = _supabase.auth.currentUser?.id ?? '';
    await _fetchLeaves(uid, 'coordinator', null);
    notifyListeners();
  }

  Future<void> updateStudent(String id, Map<String, dynamic> data) async {
    await _supabase.from('students').update(data).eq('id', id);
    notifyListeners();
  }

  Future<void> removeStudent(String id) async {
    await _supabase.from('students').delete().eq('id', id);
    _students.removeWhere((s) => s['id'] == id);
    notifyListeners();
  }

  Future<void> removeTeacher(String id) async {
    await _supabase.from('profiles').delete().eq('id', id);
    _teachers.removeWhere((t) => t['id'] == id);
    notifyListeners();
  }

  Future<void> addDiaryEntry(Map<String, dynamic> entry) async {
    final uid = _supabase.auth.currentUser?.id;
    await _supabase.from('diary_entries').insert({
      'teacher_id': uid,
      'title': entry['title'],
      'body': entry['body'],
      'category': entry['category'],
      'time': entry['time'],
      'date': entry['date'],
      'zone': entry['zone'],
      'tags': entry['tags'] ?? [],
    });
    await _fetchDiaryEntries(uid ?? '', 'teacher', entry['zone']);
    notifyListeners();
  }

  Future<void> updateDiaryEntry(String id, Map<String, dynamic> data) async {
    await _supabase.from('diary_entries').update(data).eq('id', id);
    notifyListeners();
  }

  Future<void> deleteDiaryEntry(String id) async {
    await _supabase.from('diary_entries').delete().eq('id', id);
    _diaryEntries.removeWhere((d) => d['id'] == id);
    notifyListeners();
  }

  Future<void> addResource(Map<String, dynamic> resource) async {
    final uid = _supabase.auth.currentUser?.id;
    await _supabase.from('resources').insert({
      ...resource,
      'teacher_id': uid,
    });
    await _fetchResources(uid ?? '', 'teacher');
    notifyListeners();
  }

  Future<void> addAttendance(Map<String, dynamic> record) async {
    final uid       = _supabase.auth.currentUser?.id;
    final studentId = record['studentId']?.toString(); // ← was 'student_id' (wrong key)

    await _supabase.from('attendance').upsert({
      'student_id': studentId,
      'teacher_id': uid,
      'date':       record['date'],
      'status':     record['status'],
    }, onConflict: 'student_id,date');

    // NOTE: counter updates (present_count, absent_count, total_classes) are now
    // handled automatically by the DB trigger in run_attendance_trigger.sql.
    // No manual RPC calls needed here.
  }

  /// Call this after a full attendance session is submitted so the student list
  /// in the UI immediately reflects the updated counters.
  Future<void> refreshStudentsForLocation(String? zone, String? centre) async {
    try {
      var query = _supabase.from('students').select();
      if (zone   != null && zone.isNotEmpty)   query = query.eq('zone',   zone);
      if (centre != null && centre.isNotEmpty) query = query.eq('centre', centre);
      final data = await query;
      _students = List<Map<String, dynamic>>.from(data);
      notifyListeners();
    } catch (e) {
      debugPrint('DataProvider: refreshStudentsForLocation error: $e');
    }
  }

  Future<void> addExamResult(Map<String, dynamic> exam) async {
    final uid = _supabase.auth.currentUser?.id;
    final marks = exam['marks'] as List<dynamic>;
    
    // Convert bulk marks list into individual rows for the exam_results table
    final rows = marks.map((m) => {
      'student_id': m['id'] ?? exam['studentId'], // Handle cases where ID is inside marks or at top level
      'teacher_id': uid,
      'name': m['name'] ?? exam['studentName'],
      'roll': m['roll'] ?? exam['roll'],
      'zone': exam['zone'],
      'topic': exam['topic'], // Using 'topic' as the exam name/identifier
      'total': int.tryParse(m['marks']?.toString() ?? '0'),
      'date': exam['date'],
    }).toList();

    await _supabase.from('exam_results').insert(rows);
    await _fetchExamResults(uid ?? '', 'teacher', exam['zone']);
    notifyListeners();
  }

  // ─── Announcements ────────────────────────────────────────────

  Future<void> addAnnouncement(
      String message, String zone, String authorId, String authorName) async {
    try {
      await _supabase.from('announcements').insert({
        'message': message,
        'zone': zone,
        'author_id': authorId,
        'author_name': authorName,
      });
      await _fetchAnnouncements('coordinator', zone);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating announcement: $e');
      rethrow;
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      await _supabase.from('announcements').delete().eq('id', id);
      _announcements.removeWhere((a) => a['id'] == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting announcement: $e');
      rethrow;
    }
  }

  // ─── Data Sync methods (Supabase-native) ──────────────────────
  // These are now stubs or redirect to local refreshes as Supabase 
  // handles storage and realtime updates.
  
  Future<void> refreshAllData() async {
    final uid = _supabase.auth.currentUser?.id ?? '';
    final role = _students.isNotEmpty ? 'teacher' : 'admin'; // Simplified
    await _fetchAll(uid, role, null, null);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> fetchStudentsByLocation(
      {String? zone, String? centre}) async {
    try {
      var query = _supabase.from('students').select();
      if (zone != null) query = query.eq('zone', zone);
      if (centre != null) query = query.eq('centre', centre);
      final data = await query;
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('DataProvider: fetchStudentsByLocation error: $e');
      return _students.where((s) => s['zone'] == zone && s['centre'] == centre).toList();
    }
  }

  Future<Map<String, dynamic>> fetchAttendanceFromSheet(
      String zone, String centre) async {
    return {'headers': [], 'students': []};
  }

  // ─── Reset on logout ─────────────────────────────────────────
  void reset() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
    _students = [];
    _teachers = [];
    _coordinators = [];
    _leaves = [];
    _zones = [];
    _centres = [];
    _examResults = [];
    _diaryEntries = [];
    _resources = [];
    _announcements = [];
    _isLoading = true;
    _initialized = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
