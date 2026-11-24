// lib/models/student.dart

import 'json_helpers.dart';

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

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'],
        fullName: json['fullName'],
        rollNo: json['rollNo'],
        classId: json['classId'],
      );
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

  factory ClassStudents.fromJson(Map<String, dynamic> json) => ClassStudents(
        classId: json['classId'],
        className: json['className'],
        isPublished: json['isPublished'],
        students: listFromJson(json['students'], Student.fromJson),
      );
}
