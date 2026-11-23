// lib/mock_data/dummy_db.dart
// FAKE DATABASE used only in Milestone 1 (before MySQL + the .NET API exist).
// Each class below looks like one MySQL table, and each list is the
// starting rows of that table. The same rows will later be seeded into MySQL,
// so every demo login keeps working after we switch to the real API.
// This file is deleted in Milestone 7.

class DbUser {
  int id;
  String fullName;
  String loginId;
  String password; // MOCK ONLY: plain text. The real API stores a BCrypt hash.
  String role; // 'admin' | 'teacher' | 'vp'
  String? contactEmail;
  bool mustChangePassword;

  DbUser(this.id, this.fullName, this.loginId, this.password, this.role,
      {this.contactEmail, this.mustChangePassword = false});
}

class DbSubject {
  int id;
  String name;
  int maxMarks;
  DbSubject(this.id, this.name, this.maxMarks);
}

class DbClass {
  int id;
  String gradeName;
  String section;
  int? classTeacherId;
  DateTime? resultsPublishedAt; // not null = published / locked
  DbClass(this.id, this.gradeName, this.section, this.classTeacherId);
}

class DbStudent {
  int id;
  String fullName;
  String rollNo;
  int classId;
  DbStudent(this.id, this.fullName, this.rollNo, this.classId);
}

class DbAssignment {
  int id;
  int classId;
  int subjectId;
  int teacherId;
  DateTime? submittedAt;
  DbAssignment(this.id, this.classId, this.subjectId, this.teacherId);
}

class DbMark {
  int id;
  int studentId;
  int subjectId;
  int obtained;
  int enteredBy;
  DbMark(this.id, this.studentId, this.subjectId, this.obtained, this.enteredBy);
}

class DummyDB {
  static const String schoolName = 'SLS Montessori School and College';

  // ---------------- users (password for every demo account: 123) ----------------
  static List<DbUser> users() => [
        DbUser(1, 'School Admin', 'admin@school.com', '123', 'admin'),
        DbUser(2, 'VP Sarah', 'vp@school.com', '123', 'vp'),
        DbUser(3, 'Teacher Sania', 'sania@school.com', '123', 'teacher'),
        DbUser(4, 'Teacher Ahsan', 'ahsan@school.com', '123', 'teacher'),
        DbUser(5, 'Teacher Maryam', 'maryam@school.com', '123', 'teacher'),
        DbUser(6, 'Teacher Usman', 'usman@school.com', '123', 'teacher'),
      ];

  // ---------------- subjects ----------------
  static List<DbSubject> subjects() => [
        DbSubject(1, 'English', 100),
        DbSubject(2, 'Mathematics', 100),
        DbSubject(3, 'Physics', 60),
        DbSubject(4, 'Chemistry', 60),
        DbSubject(5, 'Biology', 60),
      ];

  // ---------------- classes (class teacher id in the last column) ----------------
  static List<DbClass> classes() => [
        DbClass(1, 'Class 8', 'A', 4), // Ahsan
        DbClass(2, 'Class 8', 'B', 3), // Sania
        DbClass(3, 'Class 9', 'A', 5), // Maryam
        DbClass(4, 'Class 9', 'B', 6), // Usman
        DbClass(5, 'Class 9', 'C', null), // no class teacher yet (Admin demo)
      ];

  // ---------------- students: 5 per class ----------------
  static List<DbStudent> students() {
    const names = {
      1: ['Ali', 'Ayesha', 'Hamza', 'Hira', 'Omar'],
      2: ['Sarah', 'Ahmed', 'Zain', 'Fatima', 'Bilal'], // original roster
      3: ['Saad', 'Zara', 'Usama', 'Mahnoor', 'Fahad'],
      4: ['Danish', 'Iqra', 'Hassan', 'Sana', 'Talha'],
      5: ['Areeba', 'Junaid', 'Kinza', 'Rehan', 'Noor'],
    };
    final list = <DbStudent>[];
    var id = 1;
    names.forEach((classId, classNames) {
      for (var i = 0; i < classNames.length; i++) {
        final roll = (i + 1).toString().padLeft(2, '0'); // "01".."05"
        list.add(DbStudent(id++, classNames[i], roll, classId));
      }
    });
    return list;
  }

  // ---------------- teaching assignments ----------------
  // Every class has all 5 subjects:
  // English = Ahsan(4), Maths = Maryam(5), Physics = Usman(6),
  // Chemistry + Biology = Sania(3)
  static List<DbAssignment> assignments() {
    const teacherForSubject = {1: 4, 2: 5, 3: 6, 4: 3, 5: 3};
    final list = <DbAssignment>[];
    var id = 1;
    for (var classId = 1; classId <= 5; classId++) {
      for (var subjectId = 1; subjectId <= 5; subjectId++) {
        list.add(DbAssignment(
            id++, classId, subjectId, teacherForSubject[subjectId]!));
      }
    }
    return list;
  }

  // ---------------- marks ----------------
  // Each entry: classId, subjectId, marks for roll 01..05, submitted?
  // Chosen so the demo shows every state (Not uploaded / In progress / Submitted).
  static final List<(int, int, List<int>, bool)> _markSeeds = [
    (1, 4, [50, 44, 57, 39, 48], true), // 8-A Chemistry: submitted
    (2, 1, [85, 78, 66, 91, 72], true), // 8-B English: submitted
    (2, 2, [92, 81, 59, 88, 70], true), // 8-B Maths: submitted
    (2, 5, [52, 47, 40, 58, 45], true), // 8-B Biology: submitted
    (2, 3, [55], false), // 8-B Physics: in progress (only Sarah)
    (2, 4, [48], false), // 8-B Chemistry: in progress (only Sarah)
    (3, 1, [74, 88, 63, 95, 58], true), // 9-A: everything submitted
    (3, 2, [67, 90, 72, 84, 49], true),
    (3, 3, [41, 53, 38, 57, 46], true),
    (3, 4, [44, 56, 35, 51, 42], true),
    (3, 5, [49, 58, 43, 54, 37], true),
  ];

  static final DateTime seedSubmittedAt = DateTime(2026, 11, 20, 10, 30);

  // Builds the marks table and marks the matching assignments as submitted.
  static List<DbMark> marks(
      List<DbStudent> students, List<DbAssignment> assignments) {
    final list = <DbMark>[];
    var id = 1;
    for (final seed in _markSeeds) {
      final (classId, subjectId, values, submitted) = seed;
      final classStudents = students.where((s) => s.classId == classId).toList();
      final assignment = assignments.firstWhere(
          (a) => a.classId == classId && a.subjectId == subjectId);
      for (var i = 0; i < values.length; i++) {
        list.add(DbMark(id++, classStudents[i].id, subjectId, values[i],
            assignment.teacherId));
      }
      if (submitted) assignment.submittedAt = seedSubmittedAt;
    }
    return list;
  }
}
