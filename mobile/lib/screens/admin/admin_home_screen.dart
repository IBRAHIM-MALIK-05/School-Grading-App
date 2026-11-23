// lib/screens/admin/admin_home_screen.dart
// Admin home: list of all accounts + Reset Password + Create Account.

import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/current_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_theme.dart';
import '../../widgets/async_views.dart';
import 'create_account_screen.dart';
import 'credentials_dialog.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late Future<List<AppUser>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = dataService.getUsers();
  }

  Future<void> _reload() async {
    setState(() => _usersFuture = dataService.getUsers());
    await _usersFuture;
  }

  Future<void> _openCreateAccount() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const CreateAccountScreen()));
    _reload(); // show the new user
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

  Color _roleColor(String role) {
    if (role == 'admin') return AppColors.danger;
    if (role == 'vp') return AppColors.success;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final me = dataService.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin • Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _reload,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateAccount,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Create account'),
      ),
      body: FutureBuilder<List<AppUser>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView(message: 'Loading users...');
          }
          if (snapshot.hasError) {
            return ErrorView(error: snapshot.error!, onRetry: _reload);
          }
          final users = snapshot.data!;
          if (users.isEmpty) return const EmptyView(message: 'No users yet.');

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text('Welcome ${me.fullName}',
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text('${users.length} accounts',
                    style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 16),
                for (final user in users)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _roleColor(user.role).withValues(alpha: 0.12),
                        foregroundColor: _roleColor(user.role),
                        child: Text(user.fullName[0]),
                      ),
                      title: Text(user.fullName),
                      subtitle: Text(
                        '${user.loginId}\n${user.roleLabel}'
                        '${user.isClassTeacher ? ' of ${user.classTeacherOfClassName}' : ''}'
                        '${user.mustChangePassword ? '\n⚠ Must change password at next login' : ''}',
                      ),
                      isThreeLine: true,
                      trailing: user.id == me.id
                          ? const Text('You', style: TextStyle(color: AppColors.muted))
                          : IconButton(
                              icon: const Icon(Icons.lock_reset),
                              tooltip: 'Reset password',
                              onPressed: () => _resetPassword(user),
                            ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
