// lib/screens/teacher/teacher_dashboard.dart
// Teacher home: "My Class" card (if Class Teacher) + all subjects/classes
// this teacher must upload marks for, each with a live status chip.

import 'package:flutter/material.dart';

import '../../models/assignment.dart';
import '../../services/current_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';
import '../../widgets/status_chip.dart';
import '../shared/class_tracker_screen.dart';
import 'marks_entry.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  late Future<List<TeacherAssignment>> _future;

  @override
  void initState() {
    super.initState();
    _future = dataService.getMyAssignments();
  }

  Future<void> _reload() async {
    setState(() => _future = dataService.getMyAssignments());
    await _future;
  }

  Future<void> _openMarksEntry(TeacherAssignment a) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MarksEntryScreen(assignmentId: a.id)),
    );
    _reload(); // statuses may have changed
  }

  Future<void> _openMyClass() async {
    final user = dataService.currentUser!;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClassTrackerScreen(
            classId: user.classTeacherOfClassId!, isClassTeacher: true),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final user = dataService.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My teaching subjects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _reload,
          ),
        ],
      ),
      drawer: AppDrawer(onReturn: _reload),
      body: FutureBuilder<List<TeacherAssignment>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Loading your subjects...');
          }
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error!, onRetry: _reload);
          }
          final assignments = snapshot.data!;

          // Group by subject: "Chemistry • Out of 60" -> [8-A, 8-B, ...]
          final groups = <String, List<TeacherAssignment>>{};
          for (final a in assignments) {
            groups
                .putIfAbsent('${a.subjectName} • Out of ${a.maxMarks}', () => [])
                .add(a);
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text('Welcome ${user.fullName}',
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                if (user.isClassTeacher) _classTeacherCard(user.classTeacherOfClassName!),
                const SizedBox(height: 16),
                if (assignments.isEmpty)
                  const EmptyView(
                      message: 'No subjects are assigned to you yet.\n'
                          'Please contact the Admin.'),
                for (final entry in groups.entries) ...[
                  Text(entry.key, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 12),
                  for (final a in entry.value) _subjectCard(a),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _classTeacherCard(String className) {
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Class teacher: $className',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Track which subject teachers have uploaded marks and '
                'prepare your students\' result cards from here:'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openMyClass,
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('Open my class'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subjectCard(TeacherAssignment a) {
    final subtitle = a.isClassPublished
        ? 'Results published (locked)'
        : '${a.enteredCount}/${a.studentCount} students marked';

    return Card(
      child: ListTile(
        leading: Icon(a.isClassPublished ? Icons.lock : Icons.edit_note,
            color: Colors.black87),
        title: Text(a.className),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.muted)),
        trailing: StatusChip.submission(a.state,
            entered: a.enteredCount, total: a.studentCount),
        onTap: () => _openMarksEntry(a),
      ),
    );
  }
}
