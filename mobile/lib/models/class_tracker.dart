// lib/models/class_tracker.dart
// The Class Teacher's live view: which subject teachers have uploaded marks.

import 'json_helpers.dart';
import 'school_class.dart';
import 'student.dart';
import 'submission_state.dart';

class SubjectStatus {
  final int assignmentId; // used by the Class Teacher's "Notify" button
  final int teacherId;
  final String subjectName;
  final int maxMarks;
  final String teacherName;
  final int enteredCount;
  final int studentCount;
  final DateTime? submittedAt;

  const SubjectStatus({
    required this.assignmentId,
    required this.teacherId,
    required this.subjectName,
    required this.maxMarks,
    required this.teacherName,
    required this.enteredCount,
    required this.studentCount,
    this.submittedAt,
  });

  factory SubjectStatus.fromJson(Map<String, dynamic> json) => SubjectStatus(
        assignmentId: json['assignmentId'] ?? 0,
        teacherId: json['teacherId'] ?? 0,
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

// One subject a student's result card is still waiting for.
class WaitingOn {
  final String subjectName;
  final String teacherName;
  final String reason; // "no mark entered yet" / "not submitted yet"

  const WaitingOn({required this.subjectName, required this.teacherName, required this.reason});

  factory WaitingOn.fromJson(Map<String, dynamic> json) => WaitingOn(
        subjectName: json['subjectName'],
        teacherName: json['teacherName'],
        reason: json['reason'],
      );

  // "English (Teacher Ahsan hasn't submitted yet)"
  String get sentence => reason == 'not submitted yet'
      ? "$subjectName ($teacherName hasn't submitted yet)"
      : "$subjectName ($teacherName hasn't entered this mark yet)";
}

// Is one student's result card ready?
class StudentReadiness {
  final int studentId;
  final String fullName;
  final String rollNo;
  final bool isReady;
  final List<WaitingOn> waitingOn;

  const StudentReadiness({
    required this.studentId,
    required this.fullName,
    required this.rollNo,
    required this.isReady,
    required this.waitingOn,
  });

  factory StudentReadiness.fromJson(Map<String, dynamic> json) => StudentReadiness(
        studentId: json['studentId'],
        fullName: json['fullName'],
        rollNo: json['rollNo'],
        isReady: json['isReady'],
        waitingOn: listFromJson(json['waitingOn'], WaitingOn.fromJson),
      );
}

class ClassTracker {
  final SchoolClass schoolClass;
  final List<SubjectStatus> subjects;
  final List<Student> students;
  final List<StudentReadiness> readiness;

  const ClassTracker({
    required this.schoolClass,
    required this.subjects,
    required this.students,
    this.readiness = const [],
  });

  factory ClassTracker.fromJson(Map<String, dynamic> json) => ClassTracker(
        schoolClass: SchoolClass.fromJson(json['schoolClass']),
        subjects: listFromJson(json['subjects'], SubjectStatus.fromJson),
        students: listFromJson(json['students'], Student.fromJson),
        readiness: listFromJson(json['readiness'] ?? [], StudentReadiness.fromJson),
      );

  int get readyCount => readiness.where((r) => r.isReady).length;

  int get submittedCount =>
      subjects.where((s) => s.state == SubmissionState.submitted).length;

  bool get canPublish =>
      !schoolClass.isPublished &&
      subjects.isNotEmpty &&
      submittedCount == subjects.length;
}
