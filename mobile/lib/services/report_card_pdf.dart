// lib/services/report_card_pdf.dart
// Builds a formal, printable result card as a PDF (packages: pdf + printing).
// Works on Flutter Web (opens the browser's print dialog, which can also
// "Save as PDF") as well as on Android / Windows.

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/report_card.dart';

const _navy = PdfColor.fromInt(0xFF142D4E);
const _lightGrey = PdfColor.fromInt(0xFFF2F5F9);

// Opens the print / save-as-PDF dialog for one result card.
Future<void> printReportCard(ReportCard card) {
  return Printing.layoutPdf(
    name: 'Result card - ${card.studentName} - ${card.className}.pdf',
    onLayout: (format) => buildReportCardPdf(card, format),
  );
}

Future<Uint8List> buildReportCardPdf(ReportCard card, PdfPageFormat format) async {
  final doc = pw.Document(title: 'Result card - ${card.studentName}', author: card.schoolName);
  final now = DateTime.now();
  final date =
      '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // ---------- School header ----------
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 14),
            color: _navy,
            child: pw.Column(children: [
              pw.Text(card.schoolName,
                  style: pw.TextStyle(
                      color: PdfColors.white, fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('STUDENT RESULT CARD',
                  style: const pw.TextStyle(color: PdfColors.white, fontSize: 12, letterSpacing: 2)),
            ]),
          ),
          pw.SizedBox(height: 6),
          pw.Text(card.isPublished ? 'Final result' : 'Provisional - results not published yet',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                  fontSize: 10,
                  color: card.isPublished ? PdfColors.green800 : PdfColors.orange800)),
          pw.SizedBox(height: 18),

          // ---------- Student details ----------
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(2)},
            children: [
              _infoRow('Student Name', card.studentName),
              _infoRow('Roll No.', card.rollNo),
              _infoRow('Class', card.className),
              _infoRow('Class Teacher', card.classTeacherName ?? '-'),
            ],
          ),
          pw.SizedBox(height: 18),

          // ---------- Marks ----------
          pw.TableHelper.fromTextArray(
            headers: const ['Subject', 'Maximum Marks', 'Marks Obtained', 'Percentage'],
            data: [
              for (final line in card.lines)
                [
                  line.subjectName,
                  '${line.maxMarks}',
                  line.obtained?.toString() ?? 'Pending',
                  line.obtained == null || line.maxMarks == 0
                      ? '-'
                      : '${(line.obtained! * 100 / line.maxMarks).toStringAsFixed(1)}%',
                ],
            ],
            headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: _navy),
            oddRowDecoration: const pw.BoxDecoration(color: _lightGrey),
            cellAlignment: pw.Alignment.center,
            cellAlignments: {0: pw.Alignment.centerLeft},
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          pw.SizedBox(height: 14),

          // ---------- Totals ----------
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: _navy, width: 1)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _total('Total', '${card.totalObtained} / ${card.totalMax}'),
                _total('Percentage',
                    card.percentage == null ? '-' : '${card.percentage!.toStringAsFixed(1)}%'),
                _total('Grade', card.grade ?? '-'),
              ],
            ),
          ),
          if (!card.isComplete)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Text(
                  'Incomplete: ${card.pendingSubjects} subject(s) still waiting for marks.',
                  style: const pw.TextStyle(color: PdfColors.orange800, fontSize: 10)),
            ),

          pw.Spacer(),

          // ---------- Signatures ----------
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _signature('Class Teacher', card.classTeacherName),
              _signature('Principal', null),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Printed on $date',
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        ],
      ),
    ),
  );
  return doc.save();
}

pw.TableRow _infoRow(String label, String value) => pw.TableRow(children: [
      pw.Container(
        color: _lightGrey,
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ),
      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(value)),
    ]);

pw.Widget _total(String label, String value) => pw.Column(children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      pw.SizedBox(height: 2),
      pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
    ]);

pw.Widget _signature(String role, String? name) => pw.SizedBox(
      width: 180,
      child: pw.Column(children: [
        pw.SizedBox(height: 30),
        pw.Container(height: 0.8, color: PdfColors.black),
        pw.SizedBox(height: 4),
        pw.Text(role, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        if (name != null) pw.Text(name, style: const pw.TextStyle(fontSize: 9)),
      ]),
    );
