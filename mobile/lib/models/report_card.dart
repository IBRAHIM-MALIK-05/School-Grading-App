// lib/models/report_card.dart

import 'json_helpers.dart';

class ReportLine {
  final String subjectName;
  final int maxMarks;
  final int? obtained; // null = teacher has not entered it yet

  const ReportLine({
    required this.subjectName,
    required this.maxMarks,
    this.obtained,
  });

  factory ReportLine.fromJson(Map<String, dynamic> json) => ReportLine(
        subjectName: json['subjectName'],
        maxMarks: json['maxMarks'],
        obtained: json['obtained'],
      );
}

class ReportCard {
  final String schoolName;
  final int classId;
  final String studentName;
  final String rollNo;
  final String className;
  final String? classTeacherName;
  final List<ReportLine> lines;
  final int totalObtained;
  final int totalMax;
  final double? percentage; // null while incomplete
  final String? grade; // null while incomplete
  final bool isComplete; // every subject has a mark
  final bool isPublished; // class results published by the Class Teacher
  final bool canPrint; // only the Class Teacher of this class may print / save PDF

  const ReportCard({
    required this.schoolName,
    required this.classId,
    required this.studentName,
    required this.rollNo,
    required this.className,
    this.classTeacherName,
    required this.lines,
    required this.totalObtained,
    required this.totalMax,
    this.percentage,
    this.grade,
    required this.isComplete,
    required this.isPublished,
    this.canPrint = false,
  });

  factory ReportCard.fromJson(Map<String, dynamic> json) => ReportCard(
        schoolName: json['schoolName'],
        classId: json['classId'],
        studentName: json['studentName'],
        rollNo: json['rollNo'],
        className: json['className'],
        classTeacherName: json['classTeacherName'],
        lines: listFromJson(json['lines'], ReportLine.fromJson),
        totalObtained: json['totalObtained'],
        totalMax: json['totalMax'],
        // JSON numbers like 85 arrive as int, so convert to double
        percentage: (json['percentage'] as num?)?.toDouble(),
        grade: json['grade'],
        isComplete: json['isComplete'],
        isPublished: json['isPublished'],
        canPrint: json['canPrint'] ?? false,
      );

  int get pendingSubjects => lines.where((l) => l.obtained == null).length;
}
