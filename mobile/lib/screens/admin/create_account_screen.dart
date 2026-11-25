// lib/screens/admin/create_account_screen.dart
// Admin creates a Teacher or Principal/VP account (= "Registration"), or EDITS one later.
// The server generates the Login ID (never changes) + a temporary password.
//
// Teaching duties are picked "Subject first":
//   1. search + pick a subject (e.g. Mathematics)
//   2. search + tick the classes for it (e.g. Class 8 - A, Class 8 - B)
//   3. every duty is shown as a removable chip: "Mathematics → Class 8 - A"
// Class Teacher of: a searchable class picker (classes that already have one are greyed out).

import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../models/app_user.dart';
import '../../models/school_class.dart';
import '../../services/current_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';
import '../../widgets/search_picker.dart';
import 'credentials_dialog.dart';

class CreateAccountScreen extends StatefulWidget {
  final AppUser? existing; // null = create a new account
  const CreateAccountScreen({super.key, this.existing});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existing?.fullName ?? '');
  late final _emailController = TextEditingController(text: widget.existing?.contactEmail ?? '');

  late String _role = widget.existing?.role ?? 'teacher';
  late int? _classTeacherOfClassId = widget.existing?.classTeacherOfClassId;
  final Set<SubjectClassPair> _pairs = {}; // what this teacher will teach
  int? _pickedSubjectId; // step 1
  bool _isSaving = false;

  // Loaded from the API: classes (with who teaches what) + all subjects
  List<SchoolClass>? _classes;
  List<SubjectInfo>? _subjects;
  Object? _loadError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final overview = await dataService.getOverview();
      final subjects = await dataService.getSubjects();
      if (!mounted) return;
      setState(() {
        _classes = overview.classes;
        _subjects = subjects;
        // Editing: start with what this teacher teaches today
        if (_isEdit) {
          for (final c in overview.classes) {
            for (final s in c.subjects) {
              if (s.teacherId == widget.existing!.id) _pairs.add(SubjectClassPair(s.subjectId, c.id));
            }
          }
        }
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  SubjectInfo? _subject(int id) => _subjects!.where((s) => s.id == id).firstOrNull;
  SchoolClass? _class(int id) => _classes!.where((c) => c.id == id).firstOrNull;

  // ---------------- pickers ----------------

  Future<void> _pickClassTeacherOf() async {
    final myId = widget.existing?.id;
    final picked = await showSearchPicker<int?>(
      context,
      title: 'Class Teacher of',
      searchHint: 'Search classes',
      selected: _classTeacherOfClassId,
      items: [
        const PickerItem(value: null, title: 'Not a Class Teacher', icon: Icons.block),
        for (final c in _classes!)
          PickerItem(
            value: c.id,
            title: c.name,
            icon: Icons.class_outlined,
            // one Class Teacher per class
            enabled: c.classTeacherId == null || c.classTeacherId == myId,
            subtitle: c.classTeacherId == null
                ? 'No Class Teacher yet'
                : c.classTeacherId == myId
                    ? 'This teacher'
                    : 'Class Teacher: ${c.classTeacherName}',
          ),
      ],
    );
    if (picked != null) setState(() => _classTeacherOfClassId = picked.value);
  }

  // Step 1: which subject?
  Future<void> _pickSubject() async {
    final picked = await showSearchPicker<int>(
      context,
      title: 'Step 1 - Pick a subject',
      searchHint: 'Search subjects',
      selected: _pickedSubjectId,
      items: [
        for (final s in _subjects!)
          PickerItem(
            value: s.id,
            title: s.name,
            subtitle: 'Out of ${s.maxMarks}',
            icon: Icons.menu_book_outlined,
          ),
      ],
    );
    if (picked != null) setState(() => _pickedSubjectId = picked.value);
  }

  // Step 2: which classes for that subject?
  Future<void> _pickClasses() async {
    final subjectId = _pickedSubjectId!;
    final subject = _subject(subjectId)!;
    final myId = widget.existing?.id;

    final picked = await showMultiSearchPicker<int>(
      context,
      title: 'Step 2 - Classes for ${subject.name}',
      searchHint: 'Search classes',
      selected: {for (final p in _pairs) if (p.subjectId == subjectId) p.classId},
      items: [
        for (final c in _classes!) _classItem(c, subjectId, myId),
      ],
    );
    if (picked == null) return;
    setState(() {
      _pairs.removeWhere((p) => p.subjectId == subjectId);
      _pairs.addAll(picked.map((classId) => SubjectClassPair(subjectId, classId)));
    });
  }

  PickerItem<int> _classItem(SchoolClass c, int subjectId, int? myId) {
    final taught = c.subjects.where((s) => s.subjectId == subjectId).firstOrNull;
    if (taught == null) {
      return PickerItem(
        value: c.id,
        title: c.name,
        enabled: !c.isPublished,
        subtitle: c.isPublished
            ? 'Results published - cannot add a subject'
            : 'Not taught here yet - will be added',
      );
    }
    return PickerItem(
      value: c.id,
      title: c.name,
      subtitle: taught.teacherId == myId
          ? 'Taught by this teacher'
          : 'Now: ${taught.teacherName ?? 'nobody'} - moves to this teacher (marks kept)',
    );
  }

  // ---------------- save ----------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final isTeacher = _role == 'teacher';
    final pairs = isTeacher ? _sortedPairs() : <SubjectClassPair>[];

    try {
      if (_isEdit) {
        await dataService.updateUser(
          widget.existing!.id,
          EditUserRequest(
            fullName: _nameController.text.trim(),
            contactEmail: _emailController.text.trim(),
            classTeacherOfClassId: isTeacher ? _classTeacherOfClassId : null,
            assignments: pairs,
          ),
        );
        if (!mounted) return;
        showMessage(context, '${_nameController.text.trim()} saved.');
        Navigator.pop(context, true);
      } else {
        final credentials = await dataService.register(NewAccountRequest(
          fullName: _nameController.text.trim(),
          role: _role,
          contactEmail: _emailController.text.trim(),
          classTeacherOfClassId: isTeacher ? _classTeacherOfClassId : null,
          assignments: pairs,
        ));
        if (!mounted) return;
        await showCredentialsDialog(context, credentials, isReset: false);
        if (mounted) Navigator.pop(context, true); // back to the users list
      }
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  List<SubjectClassPair> _sortedPairs() {
    final list = _pairs.toList();
    list.sort((a, b) {
      final bySubject = _subject(a.subjectId)!.name.compareTo(_subject(b.subjectId)!.name);
      return bySubject != 0 ? bySubject : _class(a.classId)!.name.compareTo(_class(b.classId)!.name);
    });
    return list;
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit ${widget.existing!.fullName}' : 'Create Account')),
      body: _loadError != null
          ? ErrorView(error: _loadError!, onRetry: _load)
          : (_classes == null || _subjects == null)
              ? const LoadingView()
              : _buildForm(),
      bottomNavigationBar: _classes == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  icon: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(_isEdit ? Icons.save : Icons.person_add_alt_1),
                  label: Text(_isEdit ? 'Save changes' : 'Create account'),
                ),
              ),
            ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children, {String? hint}) {
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
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ]),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(hint, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Account', Icons.person_outline, [
            TextFormField(
              controller: _nameController,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Full name',
                hintText: 'e.g. Ali Raza',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Gmail (to send login details)',
                hintText: 'e.g. ali.raza@gmail.com',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            if (_isEdit)
              Text(
                'Role: ${widget.existing!.isVp ? 'Principal / VP' : 'Teacher'}\n'
                'Login ID: ${widget.existing!.loginId} (can never be changed)',
                style: const TextStyle(color: AppColors.muted),
              )
            else ...[
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'teacher', label: Text('Teacher'), icon: Icon(Icons.co_present)),
                  ButtonSegment(
                      value: 'vp', label: Text('Principal / VP'), icon: Icon(Icons.account_balance)),
                ],
                selected: {_role},
                onSelectionChanged: (value) => setState(() => _role = value.first),
              ),
              const SizedBox(height: 8),
              const Text(
                'The Login ID is generated automatically and can never be changed.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ]),
          if (_role == 'teacher') ..._teacherSections(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _teacherSections() {
    final picked = _pickedSubjectId == null ? null : _subject(_pickedSubjectId!);
    final pickedCount =
        picked == null ? 0 : _pairs.where((p) => p.subjectId == picked.id).length;
    final ctClass = _classTeacherOfClassId == null ? null : _class(_classTeacherOfClassId!);

    return [
      _section('Class Teacher (optional)', Icons.person_pin_outlined, [
        PickerField(
          label: 'Class Teacher of',
          valueText: ctClass?.name ?? 'Not a Class Teacher',
          isEmpty: ctClass == null,
          icon: Icons.groups_outlined,
          onTap: _pickClassTeacherOf,
        ),
      ], hint: 'Can add / delete students and publish result cards for that class.'),
      _section('Subjects to teach (optional)', Icons.menu_book_outlined, [
        PickerField(
          label: '1. Subject',
          valueText: picked == null ? 'Search and pick a subject' : '${picked.name} (out of ${picked.maxMarks})',
          isEmpty: picked == null,
          icon: Icons.menu_book_outlined,
          onTap: _pickSubject,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: picked == null ? null : _pickClasses,
          icon: const Icon(Icons.checklist),
          label: Text(picked == null
              ? '2. Pick class(es) - choose a subject first'
              : '2. Pick class(es) for ${picked.name} ($pickedCount selected)'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
        const SizedBox(height: 16),
        Text(
          _pairs.isEmpty ? 'No subjects yet' : 'Will teach (${_pairs.length}):',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in _sortedPairs())
              InputChip(
                avatar: const Icon(Icons.class_outlined, size: 18),
                label: Text('${_subject(p.subjectId)!.name} → ${_class(p.classId)!.name}'),
                deleteButtonTooltipMessage: 'Remove',
                onDeleted: () => setState(() => _pairs.remove(p)),
              ),
          ],
        ),
        if (_isEdit) ...[
          const SizedBox(height: 12),
          const Text(
            'Removing a subject that already has marks is refused (marks are never lost). '
            'Give it to another teacher in the Classes tab instead.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ], hint: 'Pick a subject, then the classes where this teacher teaches it.'),
    ];
  }
}
