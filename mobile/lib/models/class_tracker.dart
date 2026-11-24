// lib/models/class_tracker.dart
// The Class Teacher's live view: which subject teachers have uploaded marks.

import 'json_helpers.dart';
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

  factory SubjectStatus.fromJson(Map<String, dynamic> json) => SubjectStatus(
        subjectName: json['subjectName'],
        maxMarks: json['maxMarks'],
        teacherName: json['teacherName'],
        enteredCount: json['enteredCount'],
        studentCount: json['studentCount'],
        submittedAt: dateFromJson(json['submittedAt']),
      );

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

  factory ClassTracker.fromJson(Map<String, dynamic> json) => ClassTracker(
        schoolClass: SchoolClass.fromJson(json['schoolClass']),
        subjects: listFromJson(json['subjects'], SubjectStatus.fromJson),
        students: listFromJson(json['students'], Student.fromJson),
      );

  int get submittedCount =>
      subjects.where((s) => s.state == SubmissionState.submitted).length;

  bool get canPublish =>
      !schoolClass.isPublished &&
      subjects.isNotEmpty &&
      submittedCount == subjects.length;
}
