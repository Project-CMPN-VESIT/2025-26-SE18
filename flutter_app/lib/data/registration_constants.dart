class RegistrationConstants {
  static const Map<String, List<String>> departments = {
    '11th': ['Science', 'Commerce', 'Arts'],
    '12th': ['Science', 'Commerce', 'Arts'],
    'Graduate': ['Engineering', 'Medical', 'Science', 'Commerce', 'Arts', 'Other'],
  };

  static const List<String> classes = ['Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5', '6th', '7th', '8th', '9th', '10th', '11th', '12th', 'Graduate'];

  static List<String> getGraduationYears() {
    final now = DateTime.now().year;
    return List.generate(10, (index) => (now + index).toString());
  }
}
