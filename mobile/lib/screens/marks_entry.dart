// lib/screens/marks_entry.dart
import 'package:flutter/material.dart';
import '../mock_data/dummy_db.dart'; // Added database import
import 'report_card_view.dart';

class MarksEntry extends StatefulWidget {
  final String className;
  final String section;

  const MarksEntry({super.key, required this.className, required this.section});

  @override
  State<MarksEntry> createState() => _MarksEntryState();
}

class _MarksEntryState extends State<MarksEntry> {
  // Array to hold a focus node student
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
  
    _focusNodes = List.generate(DummyDB.students.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9),
      appBar: AppBar(
       
        title: Text('${widget.className} - Section ${widget.section} Biology', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF142D4E),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reading length dynamically from the database
                Text('Total Students: ${DummyDB.students.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text('Max Marks: 60', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: DummyDB.students.length, // Fetching length from DB
              itemBuilder: (context, index) {
                final student = DummyDB.students[index]; // Fetching student from DB
                return Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: const Color(0xFF142D4E),
                          child: Text(student['rollNo']!),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            student['name']!,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            
                            textInputAction: index == DummyDB.students.length - 1 ? TextInputAction.done : TextInputAction.next,
                            onFieldSubmitted: (_) {
                              // Move to the next field when the user hits the keyboard arrow
                              if (index < DummyDB.students.length - 1) {
                                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                              } else {
                                FocusScope.of(context).unfocus(); // Dismiss keyboard on the last entry
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Marks',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.assignment_ind, color: Color(0xFF142D4E)),
                          tooltip: 'View Report Card',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportCardView(
                                  studentName: student['name']!,
                                  rollNo: student['rollNo']!,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Marks saved successfully!'), backgroundColor: Colors.green),
              );
              Navigator.pop(context); 
            },
            icon: const Icon(Icons.save),
            label: const Text('Save Marks', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF142D4E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}