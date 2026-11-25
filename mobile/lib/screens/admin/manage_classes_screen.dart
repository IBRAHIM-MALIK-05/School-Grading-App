// lib/screens/admin/manage_classes_screen.dart
// Admin Panel > Classes tab: every class with its Class Teacher and subject teachers.
//  - Search by class name, Class Teacher or subject teacher
//  - "New class": create a class and pick its teachers
//  - "Edit" on each card: change the name, Class Teacher, subjects and their teachers
//  - "Delete" on each card: soft delete (hidden in the app, kept in the database)

import 'package:flutter/material.dart';

import '../../models/school_class.dart';
import '../../services/current_service.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';
import '../../widgets/search_picker.dart';
import 'class_editor_screen.dart';

class ClassesTab extends StatefulWidget {
  const ClassesTab({super.key});

  @override
  State<ClassesTab> createState() => _ClassesTabState();
}

class _ClassesTabState extends State<ClassesTab> with AutomaticKeepAliveClientMixin {
  late Future<SchoolOverview> _future;
  String _query = '';

  @override
  bool get wantKeepAlive => true;

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

  // Soft delete: the class leaves every list, but its students + marks stay in the database.
  Future<void> _delete(SchoolClass c) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete ${c.name}?',
      message: '${c.name} will be removed from the app, together with its subjects and '
          '${c.studentCount} student(s). Their marks are kept in the database.\n\n'
          'Its Class Teacher becomes free to lead another class.',
      confirmText: 'Delete',
      isDanger: true,
    );
    if (!ok || !mounted) return;

    try {
      final message = await dataService.softDeleteClass(c.id);
      if (!mounted) return;
      showMessage(context, message);
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), isError: true);
    }
  }

  bool _matches(SchoolClass c) {
    final q = _query.trim().toLowerCase();
    return q.isEmpty ||
        c.name.toLowerCase().contains(q) ||
        (c.classTeacherName?.toLowerCase().contains(q) ?? false) ||
        c.subjects.any((s) =>
            s.subjectName.toLowerCase().contains(q) ||
            (s.teacherName?.toLowerCase().contains(q) ?? false));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'classes',
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New class'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SearchBox(
                hint: 'Search classes or teachers',
                onChanged: (v) => setState(() => _query = v)),
          ),
          Expanded(
            child: FutureBuilder<SchoolOverview>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingView(message: 'Loading classes...');
                }
                if (snapshot.hasError) return ErrorView(error: snapshot.error!, onRetry: _reload);
                final all = snapshot.data!.classes;
                final classes = all.where(_matches).toList();

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      Text('Showing ${classes.length} of ${all.length} classes',
                          style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 8),
                      if (classes.isEmpty) const EmptyView(message: 'No class matches your search.'),
                      for (final c in classes) _classCard(c),
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

  Widget _classCard(SchoolClass c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
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
                Text('${c.studentCount} students', style: const TextStyle(color: AppColors.muted)),
                TextButton.icon(
                  onPressed: () => _openEditor(existing: c),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text('Edit', semanticsLabel: 'Edit ${c.name}'),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  tooltip: 'Delete ${c.name}',
                  onPressed: () => _delete(c),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.person_pin_outlined, size: 18, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(
                  'Class Teacher: ${c.classTeacherName ?? 'not assigned'}',
                  style: TextStyle(
                      color: c.classTeacherName == null ? AppColors.warning : null,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (c.subjects.isEmpty)
              const Text('No subjects yet', style: TextStyle(color: AppColors.muted))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in c.subjects)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('${s.subjectName} • ${s.teacherName ?? '-'}',
                          style: const TextStyle(fontSize: 12)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
