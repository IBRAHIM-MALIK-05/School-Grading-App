// lib/screens/admin/class_editor_screen.dart
// Admin: create a NEW class, or change the teachers of an EXISTING class.
//  - Class name + section (only when creating, e.g. "Class 10" + "A")
//  - Class Teacher (optional; a teacher can lead only one class)
//  - For every subject: which teacher teaches it here ("Not taught" = no teacher)
// Returns true when something was saved, so the list can reload.

import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/school_class.dart';
import '../../services/current_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';

class ClassEditorScreen extends StatefulWidget {
  final SchoolClass? existing; // null = create a new class
  const ClassEditorScreen({super.key, this.existing});

  @override
  State<ClassEditorScreen> createState() => _ClassEditorScreenState();
}

class _ClassEditorScreenState extends State<ClassEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gradeController = TextEditingController();
  final _sectionController = TextEditingController();

  List<SubjectInfo>? _subjects;
  List<AppUser>? _teachers;
  Object? _loadError;
  bool _isSaving = false;

  int? _classTeacherId;
  final Map<int, int?> _subjectTeacher = {}; // subjectId -> teacherId (null = not taught)

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    if (c != null) {
      _classTeacherId = c.classTeacherId;
      for (final s in c.subjects) {
        _subjectTeacher[s.subjectId] = s.teacherId;
      }
    }
    _load();
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final subjects = await dataService.getSubjects();
      final users = await dataService.getUsers();
      if (!mounted) return;
      setState(() {
        _subjects = subjects;
        _teachers = users.where((u) => u.isTeacher).toList();
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final request = ClassTeachersRequest(
      classTeacherId: _classTeacherId,
      // When editing, send every subject so "Not taught" can remove one
      subjectTeachers: {for (final s in _subjects!) s.id: _subjectTeacher[s.id]},
    );

    setState(() => _isSaving = true);
    try {
      final saved = _isNew
          ? await dataService.createClass(
              _gradeController.text.trim(), _sectionController.text.trim(), request)
          : await dataService.updateClassTeachers(widget.existing!.id, request);
      if (!mounted) return;
      showMessage(context, _isNew ? '${saved.name} created.' : 'Teachers of ${saved.name} saved.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'New class' : 'Teachers of ${widget.existing!.name}')),
      body: _buildBody(),
      bottomNavigationBar: _subjects == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_isNew ? 'Create class' : 'Save teachers'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_loadError != null) return ErrorView(error: _loadError!, onRetry: _load);
    if (_subjects == null || _teachers == null) return const LoadingView();
    final teachers = _teachers!;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isNew) ...[
            const Text('Class', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _gradeController,
                    maxLength: 20,
                    decoration: const InputDecoration(
                        labelText: 'Class name', hintText: 'e.g. Class 10'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Class name is required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sectionController,
                    maxLength: 5,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Section', hintText: 'A'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Section is required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          const Text('Class Teacher', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Can add / delete students and publish result cards for this class.',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _classTeacherId,
            isExpanded: true,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.person_pin_outlined)),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('No Class Teacher yet')),
              for (final t in teachers)
                DropdownMenuItem<int?>(
                  value: t.id,
                  // a teacher already leading ANOTHER class cannot be picked
                  enabled: !t.isClassTeacher || t.classTeacherOfClassId == widget.existing?.id,
                  child: Text(
                    t.isClassTeacher && t.classTeacherOfClassId != widget.existing?.id
                        ? '${t.fullName}  (already Class Teacher of ${t.classTeacherOfClassName})'
                        : t.fullName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _classTeacherId = v),
          ),
          const SizedBox(height: 24),

          const Text('Subject teachers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Who enters the marks of each subject in this class.',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 12),
          for (final s in _subjects!)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<int?>(
                initialValue: _subjectTeacher[s.id],
                isExpanded: true,
                decoration: InputDecoration(labelText: '${s.name} (out of ${s.maxMarks})'),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Not taught in this class')),
                  for (final t in teachers)
                    DropdownMenuItem<int?>(value: t.id, child: Text(t.fullName)),
                ],
                onChanged: (v) => setState(() => _subjectTeacher[s.id] = v),
              ),
            ),
          if (!_isNew)
            const Text(
              'A subject that already has marks cannot be removed. '
              'Changing its teacher keeps the marks.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
