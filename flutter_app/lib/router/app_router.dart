import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/teacher/teacher_dashboard.dart';
import '../screens/teacher/mark_attendance.dart';
import '../screens/teacher/student_list.dart';
import '../screens/teacher/add_student.dart';
import '../screens/teacher/exam_results.dart';
import '../screens/teacher/leave_request.dart';
import '../screens/teacher/teacher_diary.dart';
import '../screens/teacher/teaching_resources.dart';
import '../screens/coordinator/coordinator_dashboard.dart';
import '../screens/coordinator/manage_staff.dart';
import '../screens/coordinator/add_student.dart' as coord_student;
import '../screens/coordinator/zone_centres.dart';
import '../screens/coordinator/analytics.dart';
import '../screens/coordinator/leave_approvals.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/user_management.dart';
import '../screens/admin/zones_centres.dart';
import '../screens/admin/add_zone.dart';
import '../screens/admin/add_centre.dart';
import '../screens/admin/leave_management.dart';
import '../screens/admin/global_analytics.dart';
import '../screens/admin/attendance_summary.dart';
import '../screens/admin/add_coordinator.dart';
import '../screens/admin/add_teacher.dart' as admin_teacher;

GoRouter createRouter(AppAuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn     = authProvider.isLoggedIn;
      final loc            = state.matchedLocation;
      final isPublicRoute  = loc == '/login' || loc == '/reset-password';

      if (!isLoggedIn && !isPublicRoute) return '/login';
      if (isLoggedIn && loc == '/login') {
        switch (authProvider.role) {
          case 'teacher':
            return '/teacher';
          case 'coordinator':
            return '/coordinator';
          case 'admin':
            return '/admin';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/reset-password', builder: (context, state) => const ResetPasswordScreen()),

      // Teacher routes
      GoRoute(path: '/teacher', builder: (context, state) => const TeacherDashboard()),
      GoRoute(path: '/teacher/attendance', builder: (context, state) => const MarkAttendance()),
      GoRoute(path: '/teacher/students', builder: (context, state) => const StudentList()),
      GoRoute(path: '/teacher/students/add', builder: (context, state) => const AddStudent()),
      GoRoute(path: '/teacher/exams', builder: (context, state) => const ExamResults()),
      GoRoute(path: '/teacher/leave', builder: (context, state) => const LeaveRequest()),
      GoRoute(path: '/teacher/diary', builder: (context, state) => const TeacherDiary()),
      GoRoute(path: '/teacher/resources', builder: (context, state) => const TeachingResources()),

      // Coordinator routes
      GoRoute(path: '/coordinator', builder: (context, state) => const CoordinatorDashboard()),
      GoRoute(path: '/coordinator/manage', builder: (context, state) => const ManageStaff()),
      GoRoute(path: '/coordinator/manage/add-student', builder: (context, state) => const coord_student.CoordAddStudent()),
      GoRoute(path: '/coordinator/centres', builder: (context, state) => const ZoneCentres()),
      GoRoute(path: '/coordinator/analytics', builder: (context, state) => const AnalyticsScreen()),
      GoRoute(path: '/coordinator/leaves', builder: (context, state) => const LeaveApprovals()),
      // Admin routes
      GoRoute(path: '/admin', builder: (context, state) => const AdminDashboard()),
      GoRoute(path: '/admin/users', builder: (context, state) => const UserManagement()),
      GoRoute(path: '/admin/zones', builder: (context, state) => const ZonesCentres()),
      GoRoute(path: '/admin/zones/add', builder: (context, state) => const AddZone()),
      GoRoute(path: '/admin/centres/add', builder: (context, state) => const AddCentre()),
      GoRoute(path: '/admin/leaves', builder: (context, state) => const LeaveManagement()),
      GoRoute(path: '/admin/analytics', builder: (context, state) => const GlobalAnalytics()),
      GoRoute(path: '/admin/attendance-summary', builder: (context, state) => const AttendanceSummaryScreen()),
      GoRoute(path: '/admin/add-coordinator', builder: (context, state) => const AddCoordinator()),
      GoRoute(path: '/admin/add-teacher', builder: (context, state) => const admin_teacher.AdminAddTeacher()),
    ],
  );
}
