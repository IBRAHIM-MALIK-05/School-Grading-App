// lib/screens/admin/class_editor_screen.dart
// Admin: create a NEW class, or EDIT an existing one (name, Class Teacher, subjects, teachers).
// Everything is picked with searchable pickers (no long dropdowns):
//  - Class Teacher : only teachers who do not already lead another class
//  - Add subjects  : search the school's subjects and tick the ones taught here
//  - Each subject  : search and pick its teacher
// Saved in ONE request (POST /api/classes or PUT /api/classes/{id}).
// Returns true when something was saved, so the list can reload.

import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../models/school_class.dart';
import '../../services/current_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';
import '../../widgets/search_picker.dart';

class ClassEditorScreen extends StatefulWidget {
  final SchoolClass? existing; // null = create a new class
  const ClassEditorScreen({super.key, this.existing});

  @override
  State<ClassEditorScreen> createState() => _ClassEditorScreenState();
}

class _ClassEditorScreenState extends State<ClassEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _gradeController = TextEditingController(text: widget.existing?.gradeName ?? '');
  late final _sectionController = TextEditingController(text: widget.existing?.section ?? '');

  List<SubjectInfo>? _subjects;
  List<AppUser>? _teachers;
  Object? _loadError;
  bool _isSaving = false;
  bool _triedToSave = false; // show "pick a teacher" errors only after pressing Save

  int? _classTeacherId;
  // The subjects taught in this class -> their teacher (null = not picked yet)
  final Map<int, int?> _subjectTeacher = {};

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

  SubjectInfo? _subject(int id) => _subjects!.where((s) => s.id == id).firstOrNull;
  AppUser? _teacher(int? id) => id == null ? null : _teachers!.where((t) => t.id == id).firstOrNull;

  // ---------------- pickers ----------------

  Future<void> _pickClassTeacher() async {
    final thisClassId = widget.existing?.id;
    // Only eligible teachers: not leading ANOTHER class
    final eligible = _teachers!
        .where((t) => !t.isClassTeacher || t.classTeacherOfClassId == thisClassId)
        .toList();
    final picked = await showSearchPicker<int?>(
      context,
      title: 'Class Teacher',
      searchHint: 'Search teachers',
      selected: _classTeacherId,
      items: [
        const PickerItem(value: null, title: 'No Class Teacher yet', icon: Icons.block),
        for (final t in eligible)
          PickerItem(value: t.id, title: t.fullName, subtitle: t.loginId, icon: Icons.person_outline),
      ],
    );
    if (picked != null) setState(() => _classTeacherId = picked.value);
  }

  Future<void> _addSubjects() async {
    final available = _subjects!.where((s) => !_subjectTeacher.containsKey(s.id)).toList();
    if (available.isEmpty) {
      showMessage(context, 'Every subject is already added to this class.');
      return;
    }
    final picked = await showMultiSearchPicker<int>(
      context,
      title: 'Add subjects to this class',
      searchHint: 'Search subjects',
      items: [
        for (final s in available)
          PickerItem(value: s.id, title: s.name, subtitle: 'Out of ${s.maxMarks}', icon: Icons.menu_book_outlined),
      ],
    );
    if (picked == null || picked.isEmpty) return;
    setState(() {
      for (final id in picked) {
        _subjectTeacher[id] = null; // teacher picked next
      }
    });
  }

  Future<void> _pickSubjectTeacher(int subjectId) async {
    final picked = await showSearchPicker<int>(
      context,
      title: 'Teacher for ${_subject(subjectId)!.name}',
      searchHint: 'Search teachers',
      selected: _subjectTeacher[subjectId],
      items: [
        for (final t in _teachers!)
          PickerItem(
            value: t.id,
            title: t.fullName,
            subtitle: t.isClassTeacher ? 'Class Teacher of ${t.classTeacherOfClassName}' : t.loginId,
            icon: Icons.person_outline,
          ),
      ],
    );
    if (picked != null) setState(() => _subjectTeacher[subjectId] = picked.value);
  }

  // ---------------- save ----------------

  Future<void> _save() async {
    setState(() => _triedToSave = true);
    final formOk = _formKey.currentState!.validate();
    final missing = _subjectTeacher.entries.where((e) => e.value == null).map((e) => _subject(e.key)!.name);
    if (!formOk) return;
    if (missing.isNotEmpty) {
      showMessage(context, 'Pick a teacher for: ${missing.join(', ')}', isError: true);
      return;
    }

    // Editing: send EVERY subject so a removed one goes as "null" (= remove from class)
    final request = ClassTeachersRequest(
      classTeacherId: _classTeacherId,
      subjectTeachers: _isNew
          ? Map.of(_subjectTeacher)
          : {for (final s in _subjects!) s.id: _subjectTeacher[s.id]},
    );

    setState(() => _isSaving = true);
    try {
      final grade = _gradeController.text.trim();
      final section = _sectionController.text.trim();
      final saved = _isNew
          ? await dataService.createClass(grade, section, request)
          : await dataService.editClass(widget.existing!.id, grade, section, request);
      if (!mounted) return;
      showMessage(context, _isNew ? '${saved.name} created.' : '${saved.name} saved.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'New class' : 'Edit ${widget.existing!.name}')),
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
                  label: Text(_isNew ? 'Create class' : 'Save changes'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ),
    );
  }

  Widget _section(String title, IconData icon, String hint, List<Widget> children, {Widget? action}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
              ?action,
            ]),
            const SizedBox(height: 4),
            Text(hint, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadError != null) return ErrorView(error: _loadError!, onRetry: _load);
    if (_subjects == null || _teachers == null) return const LoadingView();

    final classTeacher = _teacher(_classTeacherId);
    final selected = _subjects!.where((s) => _subjectTeacher.containsKey(s.id)).toList();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Class', Icons.class_outlined, 'For example "Class 10" and section "A".', [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _gradeController,
                    maxLength: 20,
                    decoration: const InputDecoration(labelText: 'Class name', hintText: 'e.g. Class 10'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Class name is required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sectionController,
                    maxLength: 5,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Section', hintText: 'A'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Section is required' : null,
                  ),
                ),
              ],
            ),
          ]),
          _section('Class Teacher', Icons.person_pin_outlined,
              'Adds / deletes students and publishes the result cards of this class.', [
            PickerField(
              label: 'Class Teacher',
              valueText: classTeacher?.fullName ?? 'No Class Teacher yet',
              isEmpty: classTeacher == null,
              icon: Icons.person_pin_outlined,
              onTap: _pickClassTeacher,
            ),
          ]),
          _section(
            'Subjects & teachers (${selected.length})',
            Icons.menu_book_outlined,
            'Who enters the marks of each subject in this class.',
            [
              if (selected.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('No subjects yet. Tap "Add subjects".',
                      style: TextStyle(color: AppColors.muted)),
                ),
              for (final s in selected) _subjectRow(s),
              OutlinedButton.icon(
                onPressed: _addSubjects,
                icon: const Icon(Icons.add),
                label: const Text('Add subjects'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
              if (!_isNew)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'A subject that already has marks cannot be removed. Changing its teacher keeps the marks.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // One subject: name, its teacher (searchable picker) and a remove button
  Widget _subjectRow(SubjectInfo s) {
    final teacher = _teacher(_subjectTeacher[s.id]);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${s.name}  (out of ${s.maxMarks})',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Remove ${s.name}',
                onPressed: () => setState(() => _subjectTeacher.remove(s.id)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PickerField(
              label: 'Teacher for ${s.name}',
              valueText: teacher?.fullName ?? 'Pick a teacher',
              isEmpty: teacher == null,
              icon: Icons.person_outline,
              errorText: _triedToSave && teacher == null ? 'Please pick a teacher' : null,
              onTap: () => _pickSubjectTeacher(s.id),
            ),
          ),
        ],
      ),
    );
  }
}
