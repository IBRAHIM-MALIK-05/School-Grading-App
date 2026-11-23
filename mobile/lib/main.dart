// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Import your new screen

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF142D4E), 
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(), // Boot directly into the login screen
    );
  }
}