// lib/screens/vp/vp_dashboard.dart
// Principal / VP: school-wide overview with REAL counts
// (no more hard-coded 12 / 345 / 84) and the status of every class.

import 'package:flutter/material.dart';

import '../../models/school_class.dart';
import '../../services/current_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';
import '../../widgets/status_chip.dart';
import '../shared/class_tracker_screen.dart';

class VpDashboard extends StatefulWidget {
  const VpDashboard({super.key});

  @override
  State<VpDashboard> createState() => _VpDashboardState();
}

class _VpDashboardState extends State<VpDashboard> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Principal / VP Overview'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: _reload),
        ],
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<SchoolOverview>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Loading school overview...');
          }
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error!, onRetry: _reload);
          }
          final overview = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Welcome ${dataService.currentUser!.fullName}',
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 16),
                // 4 stat tiles (2 x 2)
                Row(
                  children: [
                    _statTile('Sections', overview.sections, Icons.class_outlined),
                    _statTile('Students', overview.students, Icons.school_outlined),
                  ],
                ),
                Row(
                  children: [
                    _statTile('Teachers', overview.teachers, Icons.co_present_outlined),
                    _statTile('Cards Ready', overview.cardsReady, Icons.task_alt),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${overview.pendingSubjects} subject submissions still pending',
                    style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 16),
                const Text('Class Grading Status',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                for (final c in overview.classes) _classCard(c),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statTile(String label, int value, IconData icon) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 30),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(label, style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _classCard(SchoolClass c) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.class_outlined),
        title: Text(c.name),
        subtitle: Text(
          '${c.studentCount} students • ${c.submittedCount}/${c.subjects.length} subjects submitted\n'
          'Class Teacher: ${c.classTeacherName ?? 'not assigned'}',
        ),
        isThreeLine: true,
        trailing: StatusChip.classStatus(c.statusLabel),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassTrackerScreen(classId: c.id, isClassTeacher: false),
            ),
          );
          _reload();
        },
      ),
    );
  }
}
