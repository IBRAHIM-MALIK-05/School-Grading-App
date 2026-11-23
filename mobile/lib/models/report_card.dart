// lib/models/report_card.dart

class ReportLine {
  final String subjectName;
  final int maxMarks;
  final int? obtained; // null = teacher has not entered it yet

  const ReportLine({
    required this.subjectName,
    required this.maxMarks,
    this.obtained,
  });
}

class ReportCard {
  final String schoolName;
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

  const ReportCard({
    required this.schoolName,
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
  });

  int get pendingSubjects => lines.where((l) => l.obtained == null).length;
}
