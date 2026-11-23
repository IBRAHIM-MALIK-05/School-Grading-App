// lib/screens/teacher_dashboard.dart
import 'package:flutter/material.dart';
import '../mock_data/dummy_db.dart';
import 'login_screen.dart';
import 'marks_entry.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold background matches the light grayish-blue from the screenshot
    final backgroundColor = const Color(0xFFF2F5F9);
    final primaryColor = const Color(0xFF142D4E);

    return Scaffold(
      backgroundColor: backgroundColor, // Added back to fix your background color
      appBar: AppBar(
        title: Text('My teaching subjects', style: TextStyle(color: primaryColor)),
        backgroundColor: backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryColor),
            onPressed: () {}, // Mock refresh
          ),
          IconButton(
            icon: Icon(Icons.logout, color: primaryColor),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header Section
          const Text(
            'Welcome Sania',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.normal),
          ),
          const SizedBox(height: 8),
         
          // Class Teacher Card
          Card(
            color: Colors.white,
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Class teacher: Class 8 - B',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate your students Result card from here :',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16), 
                  FilledButton.icon(
                    onPressed: () {
                      // Future routing for result cards
                    },
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('My result cards'),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        
          for (var subjectGroup in DummyDB.teacherSubjects.entries)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjectGroup.key,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                ),
                const SizedBox(height: 12),
                
                // Nested loop for the classes
                for (var cls in subjectGroup.value)
                  _buildSubjectCard(context, cls['title']!, cls['subtitle']!),
                
                const SizedBox(height: 24),
              ],
            ),
        ],
      ),
    );
  }
       
  // Reusable widget for the list items to keep code clean
  Widget _buildSubjectCard(BuildContext context, String title, String subtitle) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.edit_note, color: Colors.black87),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black54),
        onTap: () {
          // Extracts the class name (e.g., "Class 8") and section ("A")
          final parts = title.split(' - ');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MarksEntry(
                className: parts[0],
                section: parts.length > 1 ? parts[1] : '',
              ),
            ),
          );
        },
      ),
    );
  }
}