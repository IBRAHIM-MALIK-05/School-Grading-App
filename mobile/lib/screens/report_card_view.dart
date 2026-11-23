// lib/screens/report_card_view.dart
import 'package:flutter/material.dart';
import '../mock_data/dummy_db.dart';

class ReportCardView extends StatelessWidget {
  final String studentName;
  final String rollNo;

  const ReportCardView({super.key, required this.studentName, required this.rollNo});

  @override
  Widget build(BuildContext context) {
    //  Automatically computes totals from the database
    int totalMax = 0;
    int totalObtained = 0;
    for (var subject in DummyDB.reportCardData) {
      totalMax += subject['max'] as int;
      totalObtained += subject['obtained'] as int;
    }
    double percentage = (totalObtained / totalMax) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result Card', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF142D4E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'SLS Montessori School and College',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF142D4E)),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Divider(height: 30, thickness: 2),
                Text('Student Name: $studentName', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('Roll Number: $rollNo', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Class: Class 8 - Section B', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                
                // Table Header
                Container(
                  color: const Color(0xFF142D4E),
                  padding: const EdgeInsets.all(8),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(flex: 2, child: Text('Subject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Max', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Obtained', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                
                // EASY LOWER PART: Simple 'for' loop replacing the complex .map()
                for (var s in DummyDB.reportCardData)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(flex: 2, child: Text(s['name'])),
                        Expanded(child: Text(s['max'].toString())),
                        Expanded(child: Text(s['obtained'].toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                
                const Divider(height: 30, thickness: 2),
                
                // Final Results injected dynamically
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: $totalObtained / $totalMax', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Percentage: ${percentage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                // Simple grade logic based on the dynamic percentage
                Text(
                  'Grade: ${percentage >= 80 ? 'A+' : percentage >= 70 ? 'A' : 'B'}', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)
                ),
                
                const SizedBox(height: 24),
                const Text('Teacher Remarks:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'AI will generate remarks, this feature will be added later',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}