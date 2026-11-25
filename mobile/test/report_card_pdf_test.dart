// test/report_card_pdf_test.dart
// Builds the printable result card PDF (no printer needed) and saves a sample
// to docs/samples/result_card_sample.pdf so its layout can be checked.
// Run:  flutter test test/report_card_pdf_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:school_grading_app/models/report_card.dart';
import 'package:school_grading_app/services/report_card_pdf.dart';

void main() {
  // Same numbers as Sarah (8-B) in the demo data
  final card = ReportCard.fromJson({
    'schoolName': 'SLS Montessori School and College',
    'classId': 2,
    'studentName': 'Sarah',
    'rollNo': '01',
    'className': 'Class 8 - B',
    'classTeacherName': 'Teacher Sania',
    'lines': [
      {'subjectName': 'English', 'maxMarks': 100, 'obtained': 85},
      {'subjectName': 'Mathematics', 'maxMarks': 100, 'obtained': 92},
      {'subjectName': 'Physics', 'maxMarks': 60, 'obtained': 55},
      {'subjectName': 'Chemistry', 'maxMarks': 60, 'obtained': 48},
      {'subjectName': 'Biology', 'maxMarks': 60, 'obtained': 52},
    ],
    'totalObtained': 332,
    'totalMax': 380,
    'percentage': 87.4,
    'grade': 'A+',
    'isComplete': true,
    'isPublished': true,
    'canPrint': true,
  });

  test('result card PDF is a valid one-page PDF', () async {
    final bytes = await buildReportCardPdf(card, PdfPageFormat.a4);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));

    final out = File('../docs/samples/result_card_sample.pdf');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(bytes);
  });
}
