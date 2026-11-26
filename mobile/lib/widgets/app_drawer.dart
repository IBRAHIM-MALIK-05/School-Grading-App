// lib/widgets/app_drawer.dart
// The side menu. It shows different options for each role:
//   Admin   : Admin Panel (tabs: Users, Classes, Subjects), Manage Students
//   Teacher : My Subjects, My Class + Manage Students (only if Class Teacher)
//   VP      : School Overview
// Everyone : Change Password, Logout

import 'package:flutter/material.dart';

import '../screens/auth/change_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/shared/class_tracker_screen.dart';
import '../screens/shared/manage_students_screen.dart';
import '../services/current_service.dart';
import '../services/notification_center.dart';
import 'app_theme.dart';

class AppDrawer extends StatelessWidget {
  // Called when the user comes back from a screen opened in the menu,
  // so the home screen can reload its data (e.g. show a new user).
  final VoidCallback? onReturn;
  const AppDrawer({super.key, this.onReturn});

  // Close the drawer, then open the screen on top of the home screen
  Future<void> _open(BuildContext context, Widget screen) async {
    Navigator.pop(context);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    onReturn?.call();
  }

  void _logout(BuildContext context) {
    notificationCenter.stop(); // no more polling for notifications
    dataService.logout();
    // Remove every screen and go back to Login
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = dataService.currentUser;
    if (user == null) return const Drawer();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header: avatar, name, Login ID and role (each on its own line)
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.fromLTRB(
                16, MediaQuery.of(context).padding.top + 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0] : '?',
                    style: const TextStyle(fontSize: 24, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.fullName,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(user.loginId, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  user.isClassTeacher
                      ? 'Teacher • Class Teacher of ${user.classTeacherOfClassName}'
                      : user.roleLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(user.isAdmin
                ? 'Admin Panel'
                : user.isVp
                    ? 'School Overview'
                    : 'My Subjects'),
            onTap: () => Navigator.pop(context), // home is already open
          ),
          if (user.isClassTeacher)
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: Text('My Class (${user.classTeacherOfClassName})'),
              onTap: () => _open(
                context,
                ClassTrackerScreen(
                    classId: user.classTeacherOfClassId!, isClassTeacher: true),
              ),
            ),
          // Only the Admin or a Class Teacher (for their own class) can add / delete students
          if (user.isAdmin || user.isClassTeacher)
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('Manage Students'),
              onTap: () => _open(context, const ManageStudentsScreen()),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Change Password'),
            onTap: () =>
                _open(context, const ChangePasswordScreen(forced: false)),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('Logout', style: TextStyle(color: AppColors.danger)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
