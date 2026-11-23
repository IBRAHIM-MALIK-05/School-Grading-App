// lib/models/assignment.dart
// A "teaching assignment" = one teacher teaches one subject in one class.

import 'submission_state.dart';

class TeacherAssignment {
  final int id;
  final int classId;
  final String className; // "Class 8 - B"
  final int subjectId;
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
    required this.subjectId,
    required this.subjectName,
    required this.maxMarks,
    required this.studentCount,
    required this.enteredCount,
    this.submittedAt,
    required this.isClassPublished,
  });

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
}

// Everything the Marks Entry screen needs.
class AssignmentMarks {
  final TeacherAssignment assignment;
  final List<MarkRow> rows;

  const AssignmentMarks({required this.assignment, required this.rows});
}
