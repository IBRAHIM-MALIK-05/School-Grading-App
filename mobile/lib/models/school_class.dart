// lib/models/school_class.dart
// A class/section (e.g. "Class 8 - B") with its subjects and status.
// Used by the Admin (create account form) and the Principal/VP overview.

import 'json_helpers.dart';

class ClassSubject {
  final int assignmentId; // the row that links class + subject + teacher
  final int subjectId; // used by Admin > Manage Classes
  final String subjectName;
  final int maxMarks;
  final int? teacherId; // used by Admin > Manage Classes
  final String? teacherName;
  final bool isSubmitted;

  const ClassSubject({
    required this.assignmentId,
    required this.subjectId,
    required this.subjectName,
    required this.maxMarks,
    this.teacherId,
    this.teacherName,
    required this.isSubmitted,
  });

  factory ClassSubject.fromJson(Map<String, dynamic> json) => ClassSubject(
        assignmentId: json['assignmentId'],
        subjectId: json['subjectId'],
        subjectName: json['subjectName'],
        maxMarks: json['maxMarks'],
        teacherId: json['teacherId'],
        teacherName: json['teacherName'],
        isSubmitted: json['isSubmitted'],
      );
}

class SchoolClass {
  final int id;
  final String gradeName; // "Class 8"
  final String section; // "B"
  final int? classTeacherId;
  final String? classTeacherName;
  final int studentCount;
  final bool isPublished; // results published = marks locked
  final List<ClassSubject> subjects;

  const SchoolClass({
    required this.id,
    required this.gradeName,
    required this.section,
    this.classTeacherId,
    this.classTeacherName,
    required this.studentCount,
    required this.isPublished,
    required this.subjects,
  });

  factory SchoolClass.fromJson(Map<String, dynamic> json) => SchoolClass(
        id: json['id'],
        gradeName: json['gradeName'],
        section: json['section'],
        classTeacherId: json['classTeacherId'],
        classTeacherName: json['classTeacherName'],
        studentCount: json['studentCount'],
        isPublished: json['isPublished'],
        subjects: listFromJson(json['subjects'], ClassSubject.fromJson),
      );

  String get name => '$gradeName - $section';

  int get submittedCount => subjects.where((s) => s.isSubmitted).length;

  bool get allSubmitted =>
      subjects.isNotEmpty && submittedCount == subjects.length;

  // "Published", "Ready to publish" or "Pending"
  String get statusLabel {
    if (isPublished) return 'Published';
    if (allSubmitted) return 'Ready to publish';
    return 'Pending';
  }
}

// What the Principal/VP dashboard shows at the top.
class SchoolOverview {
  final int sections;
  final int students;
  final int teachers;
  final int cardsReady; // students in classes whose results are published
  final int pendingSubjects; // class-subjects not submitted yet
  final List<SchoolClass> classes;

  const SchoolOverview({
    required this.sections,
    required this.students,
    required this.teachers,
    required this.cardsReady,
    required this.pendingSubjects,
    required this.classes,
  });

  factory SchoolOverview.fromJson(Map<String, dynamic> json) => SchoolOverview(
        sections: json['sections'],
        students: json['students'],
        teachers: json['teachers'],
        cardsReady: json['cardsReady'],
        pendingSubjects: json['pendingSubjects'],
        classes: listFromJson(json['classes'], SchoolClass.fromJson),
      );
}

// A subject of the school (GET /api/subjects), e.g. English out of 100.
class SubjectInfo {
  final int id;
  final String name;
  final int maxMarks;

  const SubjectInfo({required this.id, required this.name, required this.maxMarks});

  factory SubjectInfo.fromJson(Map<String, dynamic> json) =>
      SubjectInfo(id: json['id'], name: json['name'], maxMarks: json['maxMarks']);
}

// What the Admin sends to create a class or change its teachers.
// subjectTeachers: subjectId -> teacherId (null = subject not taught in this class).
class ClassTeachersRequest {
  final int? classTeacherId;
  final Map<int, int?> subjectTeachers;

  const ClassTeachersRequest({this.classTeacherId, required this.subjectTeachers});

  List<Map<String, dynamic>> get subjectTeachersJson => [
        for (final e in subjectTeachers.entries) {'subjectId': e.key, 'teacherId': e.value}
      ];
}
