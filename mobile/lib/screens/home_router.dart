// lib/screens/home_router.dart
// Role-based routing: decides the first screen after login.

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import 'admin/admin_home_screen.dart';
import 'auth/change_password_screen.dart';
import 'teacher/teacher_dashboard.dart';
import 'vp/vp_dashboard.dart';

Widget homeScreenFor(AppUser user) {
  if (user.isAdmin) return const AdminHomeScreen();
  if (user.isVp) return const VpDashboard();
  return const TeacherDashboard();
}

// Called after a successful login.
// New accounts / reset passwords must set their own password first.
void goToHome(BuildContext context, AppUser user) {
  final Widget next = user.mustChangePassword
      ? const ChangePasswordScreen(forced: true)
      : homeScreenFor(user);

  // pushAndRemoveUntil = the Back button cannot return to the login screen
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => next),
    (route) => false,
  );
}
