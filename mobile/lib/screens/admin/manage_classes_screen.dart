// lib/screens/admin/manage_classes_screen.dart
// Admin > Manage Classes: every class with its Class Teacher and subject teachers.
//  - "New class": create a class and pick its Class Teacher + subject teachers.
//  - Tap a class: change its Class Teacher or who teaches each subject.

import 'package:flutter/material.dart';

import '../../models/school_class.dart';
import '../../services/current_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';
import 'class_editor_screen.dart';

class ManageClassesScreen extends StatefulWidget {
  const ManageClassesScreen({super.key});

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen> {
  late Future<SchoolOverview> _future;

  @override
  void initState() {
    super.initState();
    _future = dataService.getOverview();
  }

  Future<void> _reload() async {
    setState(() => _future = dataService.getOverview());
    await _future;
  }

  Future<void> _openEditor({SchoolClass? existing}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ClassEditorScreen(existing: existing)),
    );
    if (saved == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Classes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: _reload),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New class'),
      ),
      body: FutureBuilder<SchoolOverview>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Loading classes...');
          }
          if (snapshot.hasError) return ErrorView(error: snapshot.error!, onRetry: _reload);
          final classes = snapshot.data!.classes;
          if (classes.isEmpty) return const EmptyView(message: 'No classes yet. Tap "New class".');

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text('${classes.length} classes • tap one to change its teachers',
                    style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 12),
                for (final c in classes) _classCard(c),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _classCard(SchoolClass c) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openEditor(existing: c),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.class_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(c.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                  Text('${c.studentCount} students',
                      style: const TextStyle(color: AppColors.muted)),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Class Teacher: ${c.classTeacherName ?? 'not assigned'}',
                style: TextStyle(
                    color: c.classTeacherName == null ? AppColors.warning : null,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                c.subjects.isEmpty
                    ? 'No subject teachers yet'
                    : c.subjects.map((s) => '${s.subjectName}: ${s.teacherName ?? '-'}').join('  •  '),
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
