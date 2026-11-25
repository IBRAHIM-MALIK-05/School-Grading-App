// lib/screens/admin/admin_home_screen.dart
// Admin Panel: three tabs, each with its own search bar and "add" button.
//   Users    - accounts: search, Create account, Edit, Reset password
//   Classes  - classes: search, New class, Edit (name, Class Teacher, subjects + teachers)
//   Subjects - subjects: search, Add subject, Edit (rename / max marks), Delete if unused

import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/current_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';
import '../../widgets/search_picker.dart';
import 'create_account_screen.dart';
import 'credentials_dialog.dart';
import 'manage_classes_screen.dart';
import 'manage_subjects_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.people_alt_outlined), text: 'Users'),
              Tab(icon: Icon(Icons.class_outlined), text: 'Classes'),
              Tab(icon: Icon(Icons.menu_book_outlined), text: 'Subjects'),
            ],
          ),
        ),
        drawer: const AppDrawer(),
        body: const TabBarView(
          children: [UsersTab(), ClassesTab(), SubjectsTab()],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Users tab
class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> with AutomaticKeepAliveClientMixin {
  late Future<List<AppUser>> _usersFuture;
  String _query = '';
  String _roleFilter = 'all'; // all / teacher / vp

  // Small icon buttons, so Edit + Reset + Delete leave room for the login ID on a phone
  static const _tight = VisualDensity(horizontal: -4, vertical: -2);

  @override
  bool get wantKeepAlive => true; // keep the search when switching tabs

  @override
  void initState() {
    super.initState();
    _usersFuture = dataService.getUsers();
  }

  Future<void> _reload() async {
    setState(() => _usersFuture = dataService.getUsers());
    await _usersFuture;
  }

  Future<void> _openForm({AppUser? existing}) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => CreateAccountScreen(existing: existing)));
    _reload(); // show the new / edited user
  }

  Future<void> _resetPassword(AppUser user) async {
    final ok = await confirmDialog(
      context,
      title: 'Reset password?',
      message: 'A new temporary password will be created for '
          '${user.fullName} (${user.loginId}). Their old password stops working.',
      confirmText: 'Reset',
      isDanger: true,
    );
    if (!ok || !mounted) return;

    try {
      final credentials = await dataService.resetPassword(user.id);
      if (!mounted) return;
      await showCredentialsDialog(context, credentials, isReset: true);
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), isError: true);
    }
  }

  // Soft delete: the account is hidden and cannot log in, but stays in the database.
  Future<void> _delete(AppUser user) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete ${user.fullName}?',
      message: '${user.fullName} (${user.loginId}) will be removed from the app and can no '
          'longer log in. Marks they entered are kept.\n\n'
          'A teacher who still leads a class or teaches subjects must hand them over first.',
      confirmText: 'Delete',
      isDanger: true,
    );
    if (!ok || !mounted) return;

    try {
      final message = await dataService.softDeleteUser(user.id);
      if (!mounted) return;
      showMessage(context, message);
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, errorText(e), isError: true);
    }
  }

  bool _matches(AppUser u) {
    if (_roleFilter != 'all' && u.role != _roleFilter) return false;
    final q = _query.trim().toLowerCase();
    return q.isEmpty ||
        u.fullName.toLowerCase().contains(q) ||
        u.loginId.toLowerCase().contains(q) ||
        u.roleLabel.toLowerCase().contains(q) ||
        (u.classTeacherOfClassName?.toLowerCase().contains(q) ?? false);
  }

  Color _roleColor(String role) {
    if (role == 'admin') return AppColors.danger;
    if (role == 'vp') return AppColors.success;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final me = dataService.currentUser!;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'users',
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Create account'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SearchBox(
                hint: 'Search users by name, login ID or class',
                onChanged: (v) => setState(() => _query = v)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final f in const [('all', 'All'), ('teacher', 'Teachers'), ('vp', 'Principal / VP')])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.$2),
                      selected: _roleFilter == f.$1,
                      onSelected: (_) => setState(() => _roleFilter = f.$1),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AppUser>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingView(message: 'Loading users...');
                }
                if (snapshot.hasError) {
                  return ErrorView(error: snapshot.error!, onRetry: _reload);
                }
                final all = snapshot.data!;
                final users = all.where(_matches).toList();

                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      Text('Welcome ${me.fullName}  •  showing ${users.length} of ${all.length} accounts',
                          style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 8),
                      if (users.isEmpty) const EmptyView(message: 'No user matches your search.'),
                      for (final user in users) _userCard(user, me),
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

  Widget _userCard(AppUser user, AppUser me) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _roleColor(user.role).withValues(alpha: 0.12),
          foregroundColor: _roleColor(user.role),
          child: Text(user.fullName[0]),
        ),
        title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.loginId),
            Text(user.isClassTeacher
                // non-breaking spaces keep "Class 8 - B" together on one line
                ? 'Class Teacher • ${user.classTeacherOfClassName?.replaceAll(' ', ' ')}'
                : user.roleLabel),
            if (user.mustChangePassword)
              const Text('Must change password',
                  style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600)),
          ],
        ),
        isThreeLine: true,
        trailing: user.id == me.id || user.isAdmin
            ? const Text('You', style: TextStyle(color: AppColors.muted))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: _tight,
                    padding: const EdgeInsets.all(4),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit ${user.fullName}',
                    onPressed: () => _openForm(existing: user),
                  ),
                  IconButton(
                    visualDensity: _tight,
                    padding: const EdgeInsets.all(4),
                    icon: const Icon(Icons.lock_reset),
                    tooltip: 'Reset password',
                    onPressed: () => _resetPassword(user),
                  ),
                  IconButton(
                    visualDensity: _tight,
                    padding: const EdgeInsets.all(4),
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                    tooltip: 'Delete ${user.fullName}',
                    onPressed: () => _delete(user),
                  ),
                ],
              ),
      ),
    );
  }
}
