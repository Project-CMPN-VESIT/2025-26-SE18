class MockData {
  static const List<Map<String, dynamic>> students = [
    {'id': 1, 'name': 'Aarav Patel', 'roll': 'STU-001', 'attendance': '95%', 'status': 'active', 'class': 'Class 3', 'contact': '+91 98765 43210', 'centre': 'East Park Centre'},
    {'id': 2, 'name': 'Diya Sharma', 'roll': 'STU-002', 'attendance': '88%', 'status': 'active', 'class': 'Class 2', 'contact': '+91 98765 43211', 'centre': 'East Park Centre'},
    {'id': 3, 'name': 'Rohan Verma', 'roll': 'STU-003', 'attendance': '72%', 'status': 'active', 'class': 'Class 1', 'contact': '+91 98765 43212', 'centre': 'North Valley'},
    {'id': 4, 'name': 'Ananya Singh', 'roll': 'STU-004', 'attendance': '91%', 'status': 'active', 'class': 'Class 3', 'contact': '+91 98765 43213', 'centre': 'North Valley'},
    {'id': 5, 'name': 'Vikram Kumar', 'roll': 'STU-005', 'attendance': '65%', 'status': 'inactive', 'class': 'Class 4', 'contact': '+91 98765 43214', 'centre': 'Urban Hub'},
    {'id': 6, 'name': 'Priya Gupta', 'roll': 'STU-006', 'attendance': '97%', 'status': 'active', 'class': 'Class 5', 'contact': '+91 98765 43215', 'centre': 'Urban Hub'},
    {'id': 7, 'name': 'Arjun Das', 'roll': 'STU-007', 'attendance': '84%', 'status': 'active', 'class': 'Class 2', 'contact': '+91 98765 43216', 'centre': 'City Square'},
    {'id': 8, 'name': 'Meera Reddy', 'roll': 'STU-008', 'attendance': '90%', 'status': 'active', 'class': 'Class 1', 'contact': '+91 98765 43217', 'centre': 'City Square'},
  ];

  static const List<Map<String, dynamic>> teachers = [
    {'id': 1, 'name': 'Sarah Johnson', 'email': 'sarah@gmail.com', 'phone': '+91 99876 54321', 'centre': 'East Park Centre', 'zone': 'North', 'status': 'active', 'students': 28},
    {'id': 2, 'name': 'Robert Smith', 'email': 'robert@gmail.com', 'phone': '+91 99876 54322', 'centre': 'North Valley', 'zone': 'North', 'status': 'active', 'students': 32},
    {'id': 3, 'name': 'Maya Williams', 'email': 'maya@gmail.com', 'phone': '+91 99876 54323', 'centre': 'Urban Hub', 'zone': 'South', 'status': 'active', 'students': 25},
    {'id': 4, 'name': 'James Chen', 'email': 'james@gmail.com', 'phone': '+91 99876 54324', 'centre': 'City Square', 'zone': 'West', 'status': 'active', 'students': 30},
    {'id': 5, 'name': 'Lisa Park', 'email': 'lisa@gmail.com', 'phone': '+91 99876 54325', 'centre': 'East Park Centre', 'zone': 'North', 'status': 'inactive', 'students': 0},
  ];

  static const List<Map<String, dynamic>> coordinators = [
    {'id': 1, 'name': 'Dr. Anil Kumar', 'email': 'anil@gmail.com', 'phone': '+91 99876 12345', 'zone': 'North', 'centres': 4, 'teachers': 12, 'students': 180, 'status': 'active'},
    {'id': 2, 'name': 'Dr. Priya Nair', 'email': 'priya@gmail.com', 'phone': '+91 99876 12346', 'zone': 'South', 'centres': 3, 'teachers': 8, 'students': 120, 'status': 'active'},
    {'id': 3, 'name': 'Dr. Raj Mehta', 'email': 'raj@gmail.com', 'phone': '+91 99876 12347', 'zone': 'West', 'centres': 2, 'teachers': 6, 'students': 95, 'status': 'active'},
  ];

  static const List<Map<String, dynamic>> leaves = [
    {'id': 1, 'name': 'Sarah Johnson', 'role': 'teacher', 'type': 'Sick Leave', 'from': '2025-02-20', 'to': '2025-02-22', 'days': 3, 'status': 'pending', 'reason': 'Flu symptoms and fever', 'zone': 'North'},
    {'id': 2, 'name': 'Robert Smith', 'role': 'teacher', 'type': 'Personal', 'from': '2025-02-25', 'to': '2025-02-25', 'days': 1, 'status': 'pending', 'reason': 'Family event', 'zone': 'North'},
    {'id': 3, 'name': 'Maya Williams', 'role': 'teacher', 'type': 'Vacation', 'from': '2025-03-01', 'to': '2025-03-05', 'days': 5, 'status': 'pending', 'reason': 'Annual vacation', 'zone': 'South'},
    {'id': 4, 'name': 'James Chen', 'role': 'teacher', 'type': 'Sick Leave', 'from': '2025-02-15', 'to': '2025-02-16', 'days': 2, 'status': 'approved', 'reason': 'Doctor appointment', 'zone': 'West'},
    {'id': 5, 'name': 'Lisa Park', 'role': 'teacher', 'type': 'Personal', 'from': '2025-02-10', 'to': '2025-02-10', 'days': 1, 'status': 'denied', 'reason': 'Personal errand', 'zone': 'North'},
  ];

  static const List<Map<String, dynamic>> zones = [
    {'id': 1, 'name': 'North Zone', 'centres': 4, 'teachers': 12, 'students': 180, 'coordinator': 'Dr. Anil Kumar', 'status': 'active'},
    {'id': 2, 'name': 'South Zone', 'centres': 3, 'teachers': 8, 'students': 120, 'coordinator': 'Dr. Priya Nair', 'status': 'active'},
    {'id': 3, 'name': 'East Zone', 'centres': 5, 'teachers': 15, 'students': 210, 'coordinator': 'Pending', 'status': 'active'},
    {'id': 4, 'name': 'West Zone', 'centres': 2, 'teachers': 6, 'students': 95, 'coordinator': 'Dr. Raj Mehta', 'status': 'active'},
  ];

  static const List<Map<String, dynamic>> centres = [
    {'id': 1, 'name': 'East Park Centre', 'zone': 'North Zone', 'teachers': 4, 'students': 55, 'address': '123 Park Road, North District'},
    {'id': 2, 'name': 'North Valley', 'zone': 'North Zone', 'teachers': 3, 'students': 45, 'address': '456 Valley Lane, North District'},
    {'id': 3, 'name': 'Urban Hub', 'zone': 'South Zone', 'teachers': 5, 'students': 70, 'address': '789 Hub Street, South District'},
    {'id': 4, 'name': 'City Square', 'zone': 'West Zone', 'teachers': 3, 'students': 42, 'address': '321 Square Ave, West District'},
    {'id': 5, 'name': 'Green Meadows', 'zone': 'East Zone', 'teachers': 4, 'students': 60, 'address': '654 Meadow Path, East District'},
  ];

  static const List<Map<String, dynamic>> examResults = [
    {'id': 1, 'name': 'Aarav Patel', 'roll': 'STU-001', 'math': 88, 'science': 92, 'english': 85, 'total': 265, 'grade': 'A'},
    {'id': 2, 'name': 'Diya Sharma', 'roll': 'STU-002', 'math': 75, 'science': 80, 'english': 90, 'total': 245, 'grade': 'B+'},
    {'id': 3, 'name': 'Rohan Verma', 'roll': 'STU-003', 'math': 65, 'science': 70, 'english': 72, 'total': 207, 'grade': 'B'},
    {'id': 4, 'name': 'Ananya Singh', 'roll': 'STU-004', 'math': 92, 'science': 95, 'english': 88, 'total': 275, 'grade': 'A+'},
    {'id': 5, 'name': 'Vikram Kumar', 'roll': 'STU-005', 'math': 55, 'science': 60, 'english': 58, 'total': 173, 'grade': 'C'},
  ];

  static const List<Map<String, dynamic>> diaryEntries = [
    {
      'id': 1,
      'title': 'Morning Reading Circle',
      'body': 'Focused on phonics today. Rahul and Sarah showed significant improvement in blending sounds. Used the new picture books from the NGO kit.',
      'category': 'event',
      'time': '09:15 AM',
      'date': '2025-02-19',
      'tags': ['Literacy', 'Grade 4'],
    },
    {
      'id': 2,
      'title': 'Math Mid-term Prep',
      'body': 'Need to prepare extra worksheets for long division. Some students are still struggling with remainders. Scheduled extra help for Wednesday.',
      'category': 'planning',
      'time': '11:45 AM',
      'date': '2025-02-19',
    },
    {
      'id': 3,
      'title': 'NGO Supervisor Visit',
      'body': 'Discussed the attendance trends for the last month. Recommended adding more visual aids for the science corner.',
      'category': 'general',
      'time': '03:30 PM',
      'date': '2025-02-18',
    },
  ];

  static const List<Map<String, dynamic>> resources = [
    {'id': 1, 'name': 'Algebra_Basics_v2.pdf', 'type': 'pdf', 'size': '1.4 MB', 'date': '2025-02-19', 'subject': 'Mathematics'},
    {'id': 2, 'name': 'Human_Anatomy_Diagram.jpg', 'type': 'image', 'size': '3.2 MB', 'date': '2025-02-17', 'subject': 'Science'},
    {'id': 3, 'name': 'Lesson_Plan_Week4.docx', 'type': 'doc', 'size': '856 KB', 'date': '2025-02-15', 'subject': 'Literacy'},
    {'id': 4, 'name': 'Phonics_Exercises_A-M.pdf', 'type': 'pdf', 'size': '4.1 MB', 'date': '2025-02-13', 'subject': 'Literacy'},
    {'id': 5, 'name': 'Regional_Geography_Map.pdf', 'type': 'pdf', 'size': '6.7 MB', 'date': '2025-02-10', 'subject': 'Science'},
  ];
}
