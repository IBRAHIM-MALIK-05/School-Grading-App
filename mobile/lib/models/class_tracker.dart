// lib/models/class_tracker.dart
// The Class Teacher's live view: which subject teachers have uploaded marks.

import 'school_class.dart';
import 'student.dart';
import 'submission_state.dart';

class SubjectStatus {
  final String subjectName;
  final int maxMarks;
  final String teacherName;
  final int enteredCount;
  final int studentCount;
  final DateTime? submittedAt;

  const SubjectStatus({
    required this.subjectName,
    required this.maxMarks,
    required this.teacherName,
    required this.enteredCount,
    required this.studentCount,
    this.submittedAt,
  });

  SubmissionState get state => submissionStateFrom(
        enteredCount: enteredCount,
        studentCount: studentCount,
        submittedAt: submittedAt,
      );
}

class ClassTracker {
  final SchoolClass schoolClass;
  final List<SubjectStatus> subjects;
  final List<Student> students;

  const ClassTracker({
    required this.schoolClass,
    required this.subjects,
    required this.students,
  });

  int get submittedCount =>
      subjects.where((s) => s.state == SubmissionState.submitted).length;

  bool get canPublish =>
      !schoolClass.isPublished &&
      subjects.isNotEmpty &&
      submittedCount == subjects.length;
}
