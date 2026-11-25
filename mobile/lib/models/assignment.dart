// lib/models/assignment.dart
// A "teaching assignment" = one teacher teaches one subject in one class.

import 'json_helpers.dart';
import 'submission_state.dart';

class TeacherAssignment {
  final int id;
  final int classId;
  final String className; // "Class 8 - B"
  final String subjectName;
  final int maxMarks;
  final int studentCount;
  final int enteredCount; // how many students already have marks
  final DateTime? submittedAt; // null = not submitted yet
  final bool isClassPublished; // true = locked

  const TeacherAssignment({
    required this.id,
    required this.classId,
    required this.className,
    required this.subjectName,
    required this.maxMarks,
    required this.studentCount,
    required this.enteredCount,
    this.submittedAt,
    required this.isClassPublished,
  });

  factory TeacherAssignment.fromJson(Map<String, dynamic> json) => TeacherAssignment(
        id: json['id'],
        classId: json['classId'],
        className: json['className'],
        subjectName: json['subjectName'],
        maxMarks: json['maxMarks'],
        studentCount: json['studentCount'],
        enteredCount: json['enteredCount'],
        submittedAt: dateFromJson(json['submittedAt']),
        isClassPublished: json['isClassPublished'],
      );

  SubmissionState get state => submissionStateFrom(
        enteredCount: enteredCount,
        studentCount: studentCount,
        submittedAt: submittedAt,
      );
}

// One line on the Marks Entry screen.
class MarkRow {
  final int studentId;
  final String studentName;
  final String rollNo;
  final int? obtained; // null = no mark entered yet

  const MarkRow({
    required this.studentId,
    required this.studentName,
    required this.rollNo,
    this.obtained,
  });

  factory MarkRow.fromJson(Map<String, dynamic> json) => MarkRow(
        studentId: json['studentId'],
        studentName: json['studentName'],
        rollNo: json['rollNo'],
        obtained: json['obtained'],
      );
}

// "Ali (roll 06) was removed by the Class Teacher of Class 8 - B ..."
class RemovalNotice {
  final String studentName;
  final String rollNo;
  final String message;
  final DateTime removedAt;

  const RemovalNotice({
    required this.studentName,
    required this.rollNo,
    required this.message,
    required this.removedAt,
  });

  factory RemovalNotice.fromJson(Map<String, dynamic> json) => RemovalNotice(
        studentName: json['studentName'],
        rollNo: json['rollNo'],
        message: json['message'],
        removedAt: dateFromJson(json['removedAt'])!,
      );
}

// Everything the Marks Entry screen needs.
class AssignmentMarks {
  final TeacherAssignment assignment;
  final List<MarkRow> rows;
  final List<RemovalNotice> removedStudents; // deleted by the Class Teacher (last 30 days)

  const AssignmentMarks(
      {required this.assignment, required this.rows, this.removedStudents = const []});

  factory AssignmentMarks.fromJson(Map<String, dynamic> json) => AssignmentMarks(
        assignment: TeacherAssignment.fromJson(json['assignment']),
        rows: listFromJson(json['rows'], MarkRow.fromJson),
        removedStudents: listFromJson(json['removedStudents'] ?? [], RemovalNotice.fromJson),
      );
}
