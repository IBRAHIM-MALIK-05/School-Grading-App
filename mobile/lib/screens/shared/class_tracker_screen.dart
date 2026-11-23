// lib/screens/shared/class_tracker_screen.dart
// LIVE SUBMISSION TRACKER for one class.
//  - Class Teacher: sees which subject teachers uploaded marks,
//    opens result cards, and can Publish (lock) / Unpublish results.
//  - Principal/VP: same view, read-only (isClassTeacher = false).

import 'package:flutter/material.dart';

import '../../models/class_tracker.dart';
import '../../models/submission_state.dart';
import '../../services/current_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';
import '../../widgets/status_chip.dart';
import 'report_card_view.dart';

class ClassTrackerScreen extends StatefulWidget {
  final int classId;
  final bool isClassTeacher; // true = can publish / unpublish
  const ClassTrackerScreen(
      {super.key, required this.classId, required this.isClassTeacher});

  @override
  State<ClassTrackerScreen> createState() => _ClassTrackerScreenState();
}

class _ClassTrackerScreenState extends State<ClassTrackerScreen> {
  late Future<ClassTracker> _future;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _future = dataService.getClassTracker(widget.classId);
  }

  Future<void> _reload() async {
    setState(() => _future = dataService.getClassTracker(widget.classId));
    await _future;
  }

  Future<void> _setPublished(ClassTracker tracker, bool publish) async {
    final ok = await confirmDialog(
      context,
      title: publish ? 'Publish results?' : 'Unpublish results?',
      message: publish
          ? 'Result cards of ${tracker.schoolClass.name} become final. '
              'Subject teachers will NOT be able to change marks, '
              'and students cannot be added or removed.'
          : 'Marks of ${tracker.schoolClass.name} will be unlocked so teachers '
              'can correct them.',
      confirmText: publish ? 'Publish' : 'Unpublish',
      isDanger: !publish,
    );
    if (!ok) return;

    setState(() => _isPublishing = true);
    try {
      await dataService.setPublished(widget.classId, publish);
      if (!mounted) return;
      showMessage(context, publish ? 'Results published.' : 'Results unpublished.');
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isClassTeacher ? 'My Class' : 'Class Status'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: _reload),
        ],
      ),
      body: FutureBuilder<ClassTracker>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Checking submissions...');
          }
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error!, onRetry: _reload);
          }
          final tracker = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _headerCard(tracker),
                const SizedBox(height: 16),
                Text(
                  'Subject submissions (${tracker.submittedCount} of ${tracker.subjects.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (final s in tracker.subjects) _subjectTile(s),
                const SizedBox(height: 16),
                Text('Result cards (${tracker.students.length} students)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (tracker.students.isEmpty)
                  const EmptyView(message: 'No students in this class.'),
                for (final student in tracker.students)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(student.rollNo)),
                      title: Text(student.fullName),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ReportCardView(studentId: student.id)),
                      ),
                    ),
                  ),
                if (widget.isClassTeacher) ...[
                  const SizedBox(height: 16),
                  _publishSection(tracker),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _headerCard(ClassTracker tracker) {
    final c = tracker.schoolClass;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Class Teacher: ${c.classTeacherName ?? 'not assigned'}'),
                  Text('${c.studentCount} students'),
                ],
              ),
            ),
            StatusChip.classStatus(c.statusLabel),
          ],
        ),
      ),
    );
  }

  Widget _subjectTile(SubjectStatus s) {
    final progress = s.studentCount == 0 ? 0.0 : s.enteredCount / s.studentCount;
    final color = switch (s.state) {
      SubmissionState.submitted => AppColors.success,
      SubmissionState.inProgress => AppColors.warning,
      SubmissionState.notUploaded => AppColors.danger,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${s.subjectName}  (out of ${s.maxMarks})',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                StatusChip.submission(s.state,
                    entered: s.enteredCount, total: s.studentCount),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Teacher: ${s.teacherName}'
              '${s.submittedAt != null ? '   •   Submitted ${_date(s.submittedAt!)}' : ''}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 4),
            Text('${s.enteredCount} of ${s.studentCount} students have marks',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _publishSection(ClassTracker tracker) {
    final c = tracker.schoolClass;
    final spinner = const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));

    if (c.isPublished) {
      return FilledButton.icon(
        onPressed: _isPublishing ? null : () => _setPublished(tracker, false),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.warning,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: _isPublishing ? spinner : const Icon(Icons.lock_open),
        label: const Text('Unpublish results (unlock marks)'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: (tracker.canPublish && !_isPublishing)
              ? () => _setPublished(tracker, true)
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.success,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: _isPublishing ? spinner : const Icon(Icons.publish),
          label: const Text('Publish results'),
        ),
        if (!tracker.canPublish)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'You can publish when every subject is submitted.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ),
      ],
    );
  }
}
