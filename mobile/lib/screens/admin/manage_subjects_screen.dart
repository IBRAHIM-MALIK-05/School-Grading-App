// lib/screens/admin/manage_subjects_screen.dart
// Admin Panel > Subjects tab: every subject of the school.
//  - Search as you type
//  - "Add subject": name + maximum marks (duplicate names are refused by the API, 409)
//  - "Edit": rename or change the maximum marks
//  - "Delete": only for a subject that is not taught in any class (otherwise 409)

import 'package:flutter/material.dart';

import '../../models/school_class.dart';
import '../../services/current_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';
import '../../widgets/search_picker.dart';

class SubjectsTab extends StatefulWidget {
  const SubjectsTab({super.key});

  @override
  State<SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<SubjectsTab> with AutomaticKeepAliveClientMixin {
  late Future<List<SubjectInfo>> _future;
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = dataService.getSubjects();
  }

  Future<void> _reload() async {
    setState(() => _future = dataService.getSubjects());
    await _future;
  }

  Future<void> _openDialog({SubjectInfo? existing}) async {
    final saved = await showDialog<SubjectInfo>(
      context: context,
      builder: (_) => _SubjectDialog(existing: existing),
    );
    if (saved == null || !mounted) return;
    showMessage(context, existing == null ? '${saved.name} added.' : '${saved.name} saved.');
    _reload();
  }

  Future<void> _delete(SubjectInfo s) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete ${s.name}?',
      message: '${s.name} is not taught in any class, so it can be deleted.',
      confirmText: 'Delete',
      isDanger: true,
    );
    if (!ok) return;
    try {
      final message = await dataService.deleteSubject(s.id);
      if (!mounted) return;
      showMessage(context, message);
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'subjects',
        onPressed: () => _openDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add subject'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SearchBox(hint: 'Search subjects', onChanged: (v) => setState(() => _query = v)),
          ),
          Expanded(
            child: FutureBuilder<List<SubjectInfo>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingView(message: 'Loading subjects...');
                }
                if (snapshot.hasError) return ErrorView(error: snapshot.error!, onRetry: _reload);
                final all = snapshot.data!;
                final q = _query.trim().toLowerCase();
                final subjects = all.where((s) => s.name.toLowerCase().contains(q)).toList();

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      Text('Showing ${subjects.length} of ${all.length} subjects',
                          style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 8),
                      if (subjects.isEmpty) const EmptyView(message: 'No subject matches your search.'),
                      for (final s in subjects) _subjectCard(s),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _subjectCard(SubjectInfo s) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          foregroundColor: AppColors.primary,
          child: const Icon(Icons.menu_book_outlined, size: 20),
        ),
        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Out of ${s.maxMarks}  •  '
            '${s.classCount == 0 ? 'not taught in any class yet' : 'taught in ${s.classCount} class(es)'}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit ${s.name}',
              onPressed: () => _openDialog(existing: s),
            ),
            if (s.classCount == 0) // only unused subjects can be deleted
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                tooltip: 'Delete ${s.name}',
                onPressed: () => _delete(s),
              ),
          ],
        ),
      ),
    );
  }
}

// Add / edit one subject. Returns the saved subject (null = cancelled).
class _SubjectDialog extends StatefulWidget {
  final SubjectInfo? existing;
  const _SubjectDialog({this.existing});

  @override
  State<_SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends State<_SubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late final _maxController =
      TextEditingController(text: '${widget.existing?.maxMarks ?? 100}');
  bool _isSaving = false;
  String? _serverError;

  @override
  void dispose() {
    _nameController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _serverError = null;
    });
    try {
      final name = _nameController.text.trim();
      final max = int.parse(_maxController.text.trim());
      final saved = widget.existing == null
          ? await dataService.createSubject(name, max)
          : await dataService.updateSubject(widget.existing!.id, name, max);
      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      // e.g. 409 "A subject called English already exists." - shown inside the dialog
      if (mounted) setState(() => _serverError = errorText(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return AlertDialog(
      title: Text(isNew ? 'Add subject' : 'Edit ${widget.existing!.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              maxLength: 50, // same limit as the database
              decoration: const InputDecoration(
                  labelText: 'Subject name', hintText: 'e.g. Computer Science'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _maxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Maximum marks', hintText: '100'),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 1 || n > 1000) return 'A number from 1 to 1000';
                return null;
              },
            ),
            if (_serverError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_serverError!,
                    style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: Text(isNew ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
