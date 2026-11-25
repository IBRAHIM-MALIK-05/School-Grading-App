// lib/screens/shared/report_card_view.dart
// One student's result card, built from the marks that teachers uploaded.
// Print / Save PDF: ONLY the Class Teacher of this class (the API says so with canPrint).
// Principal/VP and Admin can view it but not print; subject teachers get 403 from the API.

import 'package:flutter/material.dart';

import '../../models/report_card.dart';
import '../../services/current_service.dart';
import '../../services/report_card_pdf.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';

class ReportCardView extends StatefulWidget {
  final int studentId;
  const ReportCardView({super.key, required this.studentId});

  @override
  State<ReportCardView> createState() => _ReportCardViewState();
}

class _ReportCardViewState extends State<ReportCardView> {
  late Future<ReportCard> _future;

  @override
  void initState() {
    super.initState();
    _future = dataService.getReportCard(widget.studentId);
  }

  bool _isPrinting = false;

  void _reload() =>
      setState(() => _future = dataService.getReportCard(widget.studentId));

  Future<void> _print(ReportCard card) async {
    setState(() => _isPrinting = true);
    try {
      await printReportCard(card); // browser / system print dialog ("Save as PDF" too)
    } catch (e) {
      if (mounted) showMessage(context, 'Could not create the PDF. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  // Only for the Class Teacher, and only when every subject has a mark
  Widget? _printBar(ReportCard card) {
    if (!card.canPrint) return null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: (card.isComplete && !_isPrinting) ? () => _print(card) : null,
              icon: _isPrinting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.print_outlined),
              label: const Text('Print / Save PDF'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            if (!card.isComplete)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Printing is available when every subject has marks.',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReportCard>(
      future: _future,
      builder: (context, snapshot) {
        final done = snapshot.connectionState == ConnectionState.done;
        final card = done && !snapshot.hasError ? snapshot.data : null;
        return Scaffold(
          appBar: AppBar(title: const Text('Result Card')),
          body: !done
              ? const LoadingView(message: 'Preparing result card...')
              : snapshot.hasError
                  ? ErrorView(error: snapshot.error!, onRetry: _reload)
                  : _buildCard(card!),
          bottomNavigationBar: card == null ? null : _printBar(card),
        );
      },
    );
  }

  Widget _buildCard(ReportCard card) {
    const headerStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.bold);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  card.schoolName,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  card.isPublished ? 'FINAL RESULT' : 'NOT PUBLISHED YET',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: card.isPublished ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
              const Divider(height: 30, thickness: 2),
              Text('Student Name: ${card.studentName}',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Roll Number: ${card.rollNo}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Class: ${card.className}', style: const TextStyle(fontSize: 16)),
              if (card.classTeacherName != null) ...[
                const SizedBox(height: 8),
                Text('Class Teacher: ${card.classTeacherName}',
                    style: const TextStyle(fontSize: 16)),
              ],
              const SizedBox(height: 24),

              // Table header
              Container(
                color: AppColors.primary,
                padding: const EdgeInsets.all(8),
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text('Subject', style: headerStyle)),
                    Expanded(child: Text('Max', style: headerStyle)),
                    Expanded(child: Text('Obtained', style: headerStyle)),
                  ],
                ),
              ),

              // One row per subject
              for (final line in card.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(line.subjectName)),
                      Expanded(child: Text(line.maxMarks.toString())),
                      Expanded(
                        child: Text(
                          line.obtained?.toString() ?? 'Pending',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: line.obtained == null ? AppColors.warning : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 30, thickness: 2),

              if (!card.isComplete)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange.shade50,
                  child: Text(
                    'Incomplete: ${card.pendingSubjects} subject(s) still waiting for marks. '
                    'Percentage and grade will appear when all marks are uploaded.',
                  ),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: ${card.totalObtained} / ${card.totalMax}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Percentage: ${card.percentage!.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Grade: ${card.grade}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: card.grade == 'F' ? AppColors.danger : AppColors.success,
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const Text('Teacher Remarks:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'AI-generated remarks will be added in a future version.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
