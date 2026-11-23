// lib/screens/admin/create_account_screen.dart
// Admin creates a Teacher or Principal/VP account (= "Registration").
// The server generates the Login ID + a temporary password.

import 'package:flutter/material.dart';

import '../../models/account.dart';
import '../../models/school_class.dart';
import '../../services/current_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';
import 'credentials_dialog.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  String _role = 'teacher';
  int? _classTeacherOfClassId; // null = not a class teacher
  final Set<int> _selectedAssignmentIds = {};
  bool _isSaving = false;

  late Future<SchoolOverview> _classesFuture; // classes + subjects for the form

  @override
  void initState() {
    super.initState();
    _classesFuture = dataService.getOverview();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final request = NewAccountRequest(
      fullName: _nameController.text.trim(),
      role: _role,
      contactEmail: _emailController.text.trim(),
      classTeacherOfClassId: _role == 'teacher' ? _classTeacherOfClassId : null,
      assignmentIds: _role == 'teacher' ? _selectedAssignmentIds.toList() : [],
    );

    try {
      final credentials = await dataService.register(request);
      if (!mounted) return;
      await showCredentialsDialog(context, credentials, isReset: false);
      if (mounted) Navigator.pop(context); // back to the users list
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: FutureBuilder<SchoolOverview>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
              error: snapshot.error!,
              onRetry: () =>
                  setState(() => _classesFuture = dataService.getOverview()),
            );
          }
          return _buildForm(snapshot.data!.classes);
        },
      ),
    );
  }

  Widget _buildForm(List<SchoolClass> classes) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full name',
              hintText: 'e.g. Ali Raza',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Gmail (to send login details)',
              hintText: 'e.g. ali.raza@gmail.com',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Email is required';
              if (!value.contains('@') || !value.contains('.')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          const Text('Role', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'teacher',
                  label: Text('Teacher'),
                  icon: Icon(Icons.co_present)),
              ButtonSegment(
                  value: 'vp',
                  label: Text('Principal / VP'),
                  icon: Icon(Icons.account_balance)),
            ],
            selected: {_role},
            onSelectionChanged: (value) => setState(() => _role = value.first),
          ),
          const SizedBox(height: 8),
          const Text(
            'The Login ID is generated automatically and can never be changed.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          if (_role == 'teacher') ..._teacherFields(classes),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isSaving ? null : _create,
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            icon: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.person_add_alt_1),
            label: const Text('Create account'),
          ),
        ],
      ),
    );
  }

  // Extra fields only for teachers: Class Teacher + subjects to teach
  List<Widget> _teacherFields(List<SchoolClass> classes) {
    return [
      const SizedBox(height: 24),
      DropdownButtonFormField<int?>(
        initialValue: _classTeacherOfClassId,
        decoration: const InputDecoration(
          labelText: 'Class Teacher of (optional)',
          prefixIcon: Icon(Icons.groups_outlined),
        ),
        items: [
          const DropdownMenuItem<int?>(
              value: null, child: Text('Not a class teacher')),
          for (final c in classes)
            DropdownMenuItem<int?>(
              value: c.id,
              enabled: c.classTeacherId == null, // one class teacher per class
              child: Text(c.classTeacherId == null
                  ? c.name
                  : '${c.name}  (${c.classTeacherName})'),
            ),
        ],
        onChanged: (value) => setState(() => _classTeacherOfClassId = value),
      ),
      const SizedBox(height: 24),
      const Text('Subjects to teach (optional)',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const Text(
        'Ticking a subject moves it from the current teacher to this new teacher.',
        style: TextStyle(color: AppColors.muted, fontSize: 13),
      ),
      const SizedBox(height: 8),
      for (final c in classes)
        Card(
          child: ExpansionTile(
            title: Text(c.name),
            subtitle: Text(
                '${c.subjects.where((s) => _selectedAssignmentIds.contains(s.assignmentId)).length} selected'),
            children: [
              for (final s in c.subjects)
                CheckboxListTile(
                  value: _selectedAssignmentIds.contains(s.assignmentId),
                  title: Text('${s.subjectName} (out of ${s.maxMarks})'),
                  subtitle: Text('Currently: ${s.teacherName ?? 'nobody'}'),
                  onChanged: (checked) => setState(() {
                    if (checked == true) {
                      _selectedAssignmentIds.add(s.assignmentId);
                    } else {
                      _selectedAssignmentIds.remove(s.assignmentId);
                    }
                  }),
                ),
            ],
          ),
        ),
    ];
  }
}
