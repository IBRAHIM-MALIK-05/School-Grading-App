// lib/screens/teacher/marks_entry.dart
// A subject teacher enters marks for one class + subject.
//  - "Save Progress": saves what is typed so far (can be incomplete) -> "Saved — Not Submitted Yet"
//  - "Review & Submit Marks": opens a review list first; only "Confirm & Final Submit"
//    there sends the final submit -> "Final Submitted" (the Class Teacher sees it).
// Rows contain ONLY the marks box. Students are added / deleted by the Class Teacher;
// if one was deleted, a notice at the top explains why the name disappeared.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/assignment.dart';
import '../../models/submission_state.dart';
import '../../services/current_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';
import '../../widgets/status_chip.dart';
import 'review_marks_screen.dart';

class MarksEntryScreen extends StatefulWidget {
  final int assignmentId;
  const MarksEntryScreen({super.key, required this.assignmentId});

  @override
  State<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends State<MarksEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  AssignmentMarks? _data; // loaded from the service
  Object? _loadError;
  bool _isSaving = false;

  // One text box + one focus node per student
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _data = null;
      _loadError = null;
    });
    try {
      final data = await dataService.getAssignmentMarks(widget.assignmentId);
      // The user may have left this screen while we waited: then dispose() already
      // ran, so creating new controllers / focus nodes now would leak them.
      if (!mounted) return;
      // (re)create a controller for every student, pre-filled with saved marks
      for (final c in _controllers) {
        c.dispose();
      }
      for (final node in _focusNodes) {
        node.dispose();
      }
      _controllers
        ..clear()
        ..addAll(data.rows.map(
            (r) => TextEditingController(text: r.obtained?.toString() ?? '')));
      _focusNodes
        ..clear()
        ..addAll(data.rows.map((_) => FocusNode()));
      setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  // studentId -> marks (null = empty box)
  Map<int, int?> _collectMarks() {
    final result = <int, int?>{};
    for (var i = 0; i < _data!.rows.length; i++) {
      final text = _controllers[i].text.trim();
      result[_data!.rows[i].studentId] = text.isEmpty ? null : int.parse(text);
    }
    return result;
  }

  // "Save Progress": keep what is typed, nothing is submitted
  Future<void> _saveProgress() async {
    final form = _formKey.currentState; // null if the class has no students
    if (form != null && !form.validate()) return;
    await _send(_collectMarks(), submit: false);
  }

  // "Review & Submit Marks": show the review list; submit only after "Confirm & Final Submit"
  Future<void> _reviewAndSubmit() async {
    final form = _formKey.currentState;
    if (form != null && !form.validate()) return;
    final marks = _collectMarks();

    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ReviewMarksScreen(
          assignment: _data!.assignment,
          rows: _data!.rows,
          marks: marks,
        ),
      ),
    );
    if (confirmed != true || !mounted) return; // "Go Back & Edit"
    await _send(marks, submit: true);
  }

  Future<void> _send(Map<int, int?> marks, {required bool submit}) async {
    setState(() => _isSaving = true);
    try {
      await dataService.saveMarks(widget.assignmentId, marks, submit: submit);
      if (!mounted) return;
      showMessage(
          context,
          submit
              ? 'Final Submitted! The Class Teacher can now see your marks.'
              : 'Progress saved — not submitted yet.');
      if (submit) {
        Navigator.pop(context);
      } else {
        _load(); // refresh the status badge
      }
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _data?.assignment;

    return Scaffold(
      appBar: AppBar(
        // Title comes from the real assignment (no hard-coded subject)
        title: Text(a == null ? 'Marks Entry' : '${a.className} • ${a.subjectName}'),
      ),
      body: _buildBody(),
      bottomNavigationBar: (a == null || a.isClassPublished) ? null : _buildButtons(),
    );
  }

  Widget _banner(IconData icon, Color color, Color background, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loadError != null) return ErrorView(error: _loadError!, onRetry: _load);
    if (_data == null) return const LoadingView(message: 'Loading students...');

    final a = _data!.assignment;
    final rows = _data!.rows;
    final locked = a.isClassPublished;

    return Column(
      children: [
        // Info bar: counts + plain-word status badge
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Students: ${rows.length}   •   Max marks: ${a.maxMarks}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              StatusChip.submission(a.state,
                  entered: a.enteredCount, total: a.studentCount),
            ],
          ),
        ),
        if (!locked)
          _banner(Icons.lightbulb_outline, AppColors.primary, Colors.blue.shade50,
              "Save your marks anytime while working. Click 'Review & Submit' when all students are graded."),
        if (locked)
          _banner(Icons.lock, AppColors.success, Colors.green.shade50,
              'Results are published by the Class Teacher. Marks are locked.'),
        if (!locked && a.state == SubmissionState.submitted)
          _banner(Icons.verified, AppColors.success, Colors.green.shade50,
              'Final Submitted. You can still correct marks and submit again until results are published.'),
        // Students the Class Teacher deleted: say so instead of letting them silently vanish
        for (final notice in _data!.removedStudents)
          _banner(Icons.person_remove_outlined, AppColors.warning, Colors.orange.shade50,
              notice.message),
        Expanded(
          child: rows.isEmpty
              ? const EmptyView(message: 'No students in this class yet.')
              : Form(
                  key: _formKey,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rows.length,
                    itemBuilder: (context, index) => _studentRow(index, a.maxMarks, locked),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _studentRow(int index, int maxMarks, bool locked) {
    final row = _data!.rows[index];
    final isLast = index == _data!.rows.length - 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              foregroundColor: AppColors.primary,
              child: Text(row.rollNo),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(row.studentName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              width: 110,
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                enabled: !locked,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
                onFieldSubmitted: (_) {
                  // Jump to the next student's box
                  if (!isLast) {
                    FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                  } else {
                    FocusScope.of(context).unfocus();
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Marks',
                  suffixText: '/$maxMarks',
                  isDense: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return null; // empty is fine while saving progress
                  final number = int.tryParse(value);
                  if (number == null || number < 0 || number > maxMarks) {
                    return '0 - $maxMarks';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _saveProgress,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Progress'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _reviewAndSubmit,
                icon: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.fact_check_outlined),
                label: const Text('Review & Submit Marks'),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
