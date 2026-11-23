// lib/models/student.dart

class Student {
  final int id;
  final String fullName;
  final String rollNo; // "01", "02" ...
  final int classId;

  const Student({
    required this.id,
    required this.fullName,
    required this.rollNo,
    required this.classId,
  });
}

// The students of one class + whether that class is locked.
class ClassStudents {
  final int classId;
  final String className;
  final bool isPublished; // if true: no adding / deleting students
  final List<Student> students;

  const ClassStudents({
    required this.classId,
    required this.className,
    required this.isPublished,
    required this.students,
  });
}
