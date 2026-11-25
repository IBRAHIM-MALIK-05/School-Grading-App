// lib/screens/shared/class_tracker_screen.dart
// "MY CLASS" for the Class Teacher (and a read-only "Class Status" for Principal/VP, Admin).
// Two simple sections:
//  1. Subjects  - one compact row each: subject, teacher, "5/5 marks entered", Submitted / Pending
//  2. Result cards - one row per student: Ready (+ View / Print) or Waiting, and EXACTLY
//     which subject + teacher the card is still waiting for. No cross-checking tables.
// The Class Teacher can also Publish (lock) / Unpublish the results at the bottom.

import 'package:flutter/material.dart';

import '../../models/class_tracker.dart';
import '../../services/current_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';
import '../../widgets/status_chip.dart';
import 'report_card_view.dart';

class ClassTrackerScreen extends StatefulWidget {
  final int classId;
  final bool isClassTeacher; // true = can publish / unpublish and print result cards
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

  Future<void> _openCard(int studentId) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => ReportCardView(studentId: studentId)));
  }

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
                const SizedBox(height: 20),
                _sectionTitle('1. Subjects',
                    '${tracker.submittedCount} of ${tracker.subjects.length} submitted'),
                if (tracker.subjects.isEmpty)
                  const EmptyView(message: 'No subjects are assigned to this class yet.'),
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < tracker.subjects.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _subjectRow(tracker.subjects[i]),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _sectionTitle('2. Result cards',
                    '${tracker.readyCount} of ${tracker.readiness.length} ready'),
                if (tracker.readiness.isEmpty)
                  const EmptyView(message: 'No students in this class.'),
                for (final r in tracker.readiness) _studentCard(r),
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

  Widget _sectionTitle(String title, String summary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Text(summary, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _headerCard(ClassTracker tracker) {
    final c = tracker.schoolClass;
    return Card(
      elevation: 2,
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
                  Text('${c.studentCount} students',
                      style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
            StatusChip.classStatus(c.statusLabel),
          ],
        ),
      ),
    );
  }

  // One compact line per subject
  Widget _subjectRow(SubjectStatus s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.subjectName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${s.teacherName}  •  ${s.enteredCount}/${s.studentCount} marks entered',
                    style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              ],
            ),
          ),
          StatusChip.classTeacherView(s.state),
        ],
      ),
    );
  }

  // One student: Ready (with View / Print) or Waiting (with the exact subjects + teachers)
  Widget _studentCard(StudentReadiness r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 18, child: Text(r.rollNo, style: const TextStyle(fontSize: 13))),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(r.fullName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                StatusChip.cardReady(r.isReady),
              ],
            ),
            if (r.isReady)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openCard(r.studentId),
                  icon: Icon(widget.isClassTeacher ? Icons.print_outlined : Icons.visibility_outlined,
                      size: 18),
                  label: Text(widget.isClassTeacher ? 'View / Print Result Card' : 'View Result Card'),
                ),
              )
            else ...[
              const SizedBox(height: 6),
              for (final w in r.waitingOn)
                Padding(
                  padding: const EdgeInsets.only(left: 48, top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.hourglass_bottom, size: 14, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Waiting on: ${w.sentence}',
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _openCard(r.studentId),
                  child: const Text('View incomplete card'),
                ),
              ),
            ],
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
