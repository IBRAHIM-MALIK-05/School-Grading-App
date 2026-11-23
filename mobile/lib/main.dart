// lib/main.dart
import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'widgets/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Grading App',
      debugShowCheckedModeBanner: false, // Removes the red debug banner
      theme: buildAppTheme(),
      home: const LoginScreen(), // Boot directly into the login screen
    );
  }
}
