// lib/screens/shared/manage_students_screen.dart
// Opened from the side menu ("Manage Students") by Admin and Teachers.
//  - Admin: every class.  Teacher: classes they teach or are Class Teacher of.
//  - Add a student (name + roll number) and delete with a confirmation popup.
//  - Blocked while the class results are published (locked).
//  - Adding a student makes that class's subjects "not submitted" again,
//    because the new student has no marks yet.

import 'package:flutter/material.dart';

import '../../models/student.dart';
import '../../services/current_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  // classId -> class name, for the dropdown
  Map<int, String>? _classOptions;
  Object? _optionsError;

  int? _selectedClassId;
  Future<ClassStudents>? _studentsFuture;
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _loadClassOptions();
  }

  // Which classes can this user manage?
  Future<void> _loadClassOptions() async {
    setState(() {
      _classOptions = null;
      _optionsError = null;
    });
    try {
      final user = dataService.currentUser!;
      final options = <int, String>{};
      if (user.isAdmin) {
        final overview = await dataService.getOverview();
        for (final c in overview.classes) {
          options[c.id] = c.name;
        }
      } else {
        if (user.isClassTeacher) {
          options[user.classTeacherOfClassId!] = user.classTeacherOfClassName!;
        }
        final assignments = await dataService.getMyAssignments();
        for (final a in assignments) {
          options[a.classId] = a.className;
        }
      }
      final sortedIds = options.keys.toList()..sort();
      if (!mounted) return; // screen closed while loading
      setState(() {
        _classOptions = {for (final id in sortedIds) id: options[id]!};
        if (sortedIds.isNotEmpty) _selectClass(sortedIds.first);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _optionsError = e);
    }
  }

  void _selectClass(int classId) {
    _selectedClassId = classId;
    _studentsFuture = dataService.getClassStudents(classId);
  }

  Future<void> _reloadStudents() async {
    if (_selectedClassId == null) return;
    setState(() => _selectClass(_selectedClassId!));
    await _studentsFuture;
  }

  Future<void> _addStudent(ClassStudents data) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _AddStudentDialog(className: data.className),
    );
    if (result == null) return;

    setState(() => _isWorking = true);
    try {
      final student = await dataService.addStudent(data.classId, result.$1, result.$2);
      if (!mounted) return;
      showMessage(context,
          '${student.fullName} added (roll ${student.rollNo}). Teachers must enter marks and submit again.');
      _reloadStudents();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _deleteStudent(Student student) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete student?',
      message: 'Delete ${student.fullName} (roll ${student.rollNo})?\n\n'
          'All of this student\'s marks in every subject will also be deleted. '
          'This cannot be undone.',
      confirmText: 'Delete',
      isDanger: true,
    );
    if (!ok) return;

    setState(() => _isWorking = true);
    try {
      await dataService.deleteStudent(student.id);
      if (!mounted) return;
      showMessage(context, '${student.fullName} deleted.');
      _reloadStudents();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Students')),
      body: _buildBody(),
      floatingActionButton: _buildAddButton(),
    );
  }

  Widget? _buildAddButton() {
    if (_studentsFuture == null) return null;
    return FutureBuilder<ClassStudents>(
      future: _studentsFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done ||
            data == null ||
            data.isPublished) {
          return const SizedBox.shrink(); // no "Add" while loading or locked
        }
        return FloatingActionButton.extended(
          onPressed: _isWorking ? null : () => _addStudent(data),
          icon: const Icon(Icons.person_add),
          label: const Text('Add student'),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_optionsError != null) {
      return ErrorView(error: _optionsError!, onRetry: _loadClassOptions);
    }
    if (_classOptions == null) return const LoadingView();
    if (_classOptions!.isEmpty) {
      return const EmptyView(message: 'You have no classes to manage yet.');
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<int>(
            initialValue: _selectedClassId,
            decoration: const InputDecoration(
              labelText: 'Class',
              prefixIcon: Icon(Icons.class_outlined),
              filled: true,
              fillColor: Colors.white,
            ),
            items: [
              for (final entry in _classOptions!.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (id) {
              if (id != null) setState(() => _selectClass(id));
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<ClassStudents>(
            future: _studentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingView(message: 'Loading students...');
              }
              if (snapshot.hasError) {
                return ErrorView(error: snapshot.error!, onRetry: _reloadStudents);
              }
              return _studentList(snapshot.data!);
            },
          ),
        ),
      ],
    );
  }

  Widget _studentList(ClassStudents data) {
    return RefreshIndicator(
      onRefresh: _reloadStudents,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          if (data.isPublished)
            Card(
              color: Colors.green.shade50,
              child: const ListTile(
                leading: Icon(Icons.lock, color: AppColors.success),
                title: Text('Results published – class is locked'),
                subtitle: Text(
                    'Ask the Class Teacher to unpublish results before adding or deleting students.'),
              ),
            ),
          Text('${data.students.length} students in ${data.className}',
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 8),
          if (data.students.isEmpty)
            const EmptyView(message: 'No students yet. Tap "Add student".'),
          for (final student in data.students)
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(student.rollNo)),
                title: Text(student.fullName),
                subtitle: Text('Roll No. ${student.rollNo}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.danger,
                  tooltip: 'Delete student',
                  onPressed: (data.isPublished || _isWorking)
                      ? null
                      : () => _deleteStudent(student),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Popup with 2 fields: name + roll number. Returns (name, rollNo).
class _AddStudentDialog extends StatefulWidget {
  final String className;
  const _AddStudentDialog({required this.className});

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rollController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add student to ${widget.className}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Student name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rollController,
              decoration: const InputDecoration(
                  labelText: 'Roll number', hintText: 'e.g. 06'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Roll number is required' : null,
            ),
            const SizedBox(height: 12),
            const Text(
              'Note: all subjects of this class will need to be submitted again.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
                context, (_nameController.text.trim(), _rollController.text.trim()));
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
