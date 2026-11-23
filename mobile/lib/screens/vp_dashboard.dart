// lib/screens/vp_dashboard.dart
import 'package:flutter/material.dart';
import '../mock_data/dummy_db.dart'; 
import 'login_screen.dart';

class VpDashboard extends StatelessWidget {
  const VpDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VP Overview', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade800, 
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Sections', '12'),
                _buildStatColumn('Students', '345'),
                _buildStatColumn('Cards Ready', '84'),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Class Grading Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (var cls in DummyDB.vpClasses)
                  Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.class_outlined),
                      title: Text('${cls['class']} - Section ${cls['section']}'),
                      subtitle: Text('${cls['students']} Students'),
                      trailing: Chip(
                        label: Text(
                          cls['status'],
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        // Simple conditional logic for the color
                        backgroundColor: cls['status'] == 'Complete' ? Colors.green : Colors.orange,
                      ),
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
      ],
    );
  }
}