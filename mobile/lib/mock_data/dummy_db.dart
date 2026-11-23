// lib/mock_data/dummy_db.dart
class DummyDB {
  //  Authentication Data
  static const Map<String, dynamic> users = {
    'sania@school.com': {
      'password': '123', 
      'role': 'teacher', 
      'name': 'Teacher Sania'
    },
    'vp@school.com': {
      'password': '123', 
      'role': 'vp', 
      'name': 'VP Sarah'
    },
  };

  //  VP Dashboard Data
  static const List<Map<String, dynamic>> vpClasses = [
    {'class': 'Class 8', 'section': 'A', 'students': 25, 'status': 'Pending Entry'},
    {'class': 'Class 8', 'section': 'B', 'students': 30, 'status': 'Complete'},
    {'class': 'Class 9', 'section': 'A', 'students': 28, 'status': 'Complete'},
    {'class': 'Class 9', 'section': 'B', 'students': 32, 'status': 'Pending Entry'},
  ];

  //  Teacher Dashboard Data 
  static const Map<String,dynamic> teacherSubjects = {
    'Chemistry • Out of 60': [
      {'title': 'Class 8 - A', 'subtitle': '10 students • Marks complete'},
      {'title': 'Class 8 - B', 'subtitle': '10 students • Pending marks entry'},
      {'title': 'Class 9 - A', 'subtitle': '10 students • Pending marks entry'},
      {'title': 'Class 9 - B', 'subtitle': '10 students • Pending marks entry'},
      {'title': 'Class 9 - C', 'subtitle': '10 students • Pending marks entry'},
    ],
    'Biology • Out of 60': [
      {'title': 'Class 8 - A', 'subtitle': '10 students • Pending marks entry'},
      {'title': 'Class 8 - B', 'subtitle': '10 students • Marks complete'},
      {'title': 'Class 9 - A', 'subtitle': '10 students • Pending marks entry'},
      {'title': 'Class 9 - B', 'subtitle': '10 students • Pending marks entry'},
      {'title': 'Class 9 - C', 'subtitle': '10 students • Pending marks entry'},
    ]
  };

  //  Marks Entry Student Roster
  static const List<Map<String,dynamic>> students = [
    {'name': 'Sarah', 'rollNo': '01'},
    {'name': 'Ahmed', 'rollNo': '02'},
    {'name': 'Zain', 'rollNo': '03'},
    {'name': 'Fatima', 'rollNo': '04'},
    {'name': 'Bilal', 'rollNo': '05'},
  ];

  // 5. Mock Report Card Data
  static const List<Map<String, dynamic>> reportCardData = [
    {'name': 'English', 'max': 100, 'obtained': 85},
    {'name': 'Mathematics', 'max': 100, 'obtained': 92},
    {'name': 'Physics', 'max': 60, 'obtained': 55},
    {'name': 'Chemistry', 'max': 60, 'obtained': 48},
    {'name': 'Biology', 'max': 60, 'obtained': 52},
  ];
}