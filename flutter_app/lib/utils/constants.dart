const Map<String, Map<String, String>> validUsers = {
  'teacher@gmail.com': {'password': 'teacher123', 'role': 'teacher', 'name': 'Teacher'},
  'coordinator@gmail.com': {'password': 'coordinator123', 'role': 'coordinator', 'name': 'Coordinator'},
  'admin@gmail.com': {'password': 'admin123', 'role': 'admin', 'name': 'Admin'},
};

class Roles {
  static const String teacher = 'teacher';
  static const String coordinator = 'coordinator';
  static const String admin = 'admin';
}
