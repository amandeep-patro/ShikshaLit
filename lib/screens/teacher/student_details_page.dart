import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:literacy_check/screens/teacher/lit_test/home_screen.dart';
import 'package:literacy_check/services/scores_service.dart';
import 'test_flow_page.dart';
import 'student_results_page.dart'; // Add this import

class StudentDetailsPage extends StatelessWidget {
  final DocumentSnapshot student;

  const StudentDetailsPage({Key? key, required this.student}) : super(key: key);

  // Add this method to check if results exist
  Future<bool> _checkResultsExist(String studentId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('results')
            .doc(studentId)
            .get();
    return doc.exists;
  }

  @override
  Widget build(BuildContext context) {
    final String name = student['name'] ?? 'No Name';
    final String studentId = student['studentId'] ?? 'N/A';
    final String teacherId = student['teacherId'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(title: Text('Student Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Details Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name: $name',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Student ID: $studentId',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Teacher ID: $teacherId',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Take Test Button
            ElevatedButton(
              onPressed: () async {
                // Clear any previous scores
                await ScoresService.clearAllScores();

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                ).then((_) {
                  // After all tests are completed, navigate to test flow
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TestFlowPage(studentId: studentId),
                    ),
                  );
                });
              },
              child: Text('Take Test'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 10),
            // View Results Button
            ElevatedButton(
              onPressed: () async {
                final hasResults = await _checkResultsExist(studentId);
                if (!hasResults) {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text('No Results Found'),
                          content: Text(
                            'This student hasn\'t taken any tests yet. Would you like to conduct a test now?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            TestFlowPage(studentId: studentId),
                                  ),
                                );
                              },
                              child: Text('Take Test'),
                            ),
                          ],
                        ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentResultsPage(student: student),
                  ),
                );
              },
              child: Text('View Results'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
