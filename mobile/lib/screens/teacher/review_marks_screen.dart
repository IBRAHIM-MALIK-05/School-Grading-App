// lib/screens/teacher/review_marks_screen.dart
// The last check before a FINAL submit. Nothing is sent from here:
//  - "Go Back & Edit"          -> returns false (back to the marks boxes)
//  - "Confirm & Final Submit"  -> returns true  (the marks screen then submits)
// "Confirm" is disabled while any student has no marks.

import 'package:flutter/material.dart';

import '../../models/assignment.dart';
import '../../widgets/app_theme.dart';

// Same grade scale as the API (helpers/GradeHelper.cs)
String gradeFor(double percentage) {
  if (percentage >= 80) return 'A+';
  if (percentage >= 70) return 'A';
  if (percentage >= 60) return 'B';
  if (percentage >= 50) return 'C';
  if (percentage >= 40) return 'D';
  return 'F';
}

class ReviewMarksScreen extends StatelessWidget {
  final TeacherAssignment assignment;
  final List<MarkRow> rows;
  final Map<int, int?> marks; // studentId -> marks typed (null = empty)

  const ReviewMarksScreen({
    super.key,
    required this.assignment,
    required this.rows,
    required this.marks,
  });

  @override
  Widget build(BuildContext context) {
    final max = assignment.maxMarks;
    final graded = rows.where((r) => marks[r.studentId] != null).length;
    final missing = rows.length - graded;
    final zeros = rows.where((r) => marks[r.studentId] == 0).length;
    final canSubmit = rows.isNotEmpty && missing == 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Review marks before submitting')),
      body: Column(
        children: [
          // Summary
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${assignment.className} • ${assignment.subjectName}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$graded of ${rows.length} students graded   •   out of $max',
                    style: TextStyle(
                        color: missing == 0 ? AppColors.success : AppColors.danger,
                        fontWeight: FontWeight.w600)),
                if (missing > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                        '$missing student(s) have no marks. Go back and fill every box '
                        'to submit (or use Save Progress for now).',
                        style: const TextStyle(color: AppColors.danger)),
                  ),
                if (zeros > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('$zeros student(s) have 0 marks — please double-check.',
                        style: const TextStyle(color: AppColors.warning)),
                  ),
              ],
            ),
          ),
          // Table header
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                SizedBox(width: 44, child: Text('Roll', style: _header)),
                Expanded(child: Text('Student', style: _header)),
                SizedBox(width: 78, child: Text('Marks', style: _header)),
                SizedBox(width: 64, child: Text('%  Grade', style: _header)),
              ],
            ),
          ),
          // Scrollable list of every student
          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _row(rows[i], max),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, false),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Go Back & Edit'),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canSubmit ? () => Navigator.pop(context, true) : null,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Confirm & Final Submit'),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _header = TextStyle(color: Colors.white, fontWeight: FontWeight.bold);

  Widget _row(MarkRow row, int max) {
    final value = marks[row.studentId];
    String? warning;
    Color? warningColor;
    if (value == null) {
      warning = 'Missing marks';
      warningColor = AppColors.danger;
    } else if (value == 0) {
      warning = '0 marks — please check';
      warningColor = AppColors.warning;
    }
    final percent = value == null || max == 0 ? null : value * 100 / max;

    return Container(
      color: value == null ? Colors.red.shade50 : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text(row.rollNo)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (warning != null)
                  Text(warning, style: TextStyle(color: warningColor, fontSize: 12)),
              ],
            ),
          ),
          SizedBox(
            width: 78,
            child: Text(value == null ? '— / $max' : '$value / $max',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            width: 64,
            child: Text(percent == null
                ? '-'
                : '${percent.toStringAsFixed(0)}%  ${gradeFor(percent)}'),
          ),
        ],
      ),
    );
  }
}
