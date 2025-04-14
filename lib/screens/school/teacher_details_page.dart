import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherDetailsPage extends StatelessWidget {
  final DocumentSnapshot? teacherDoc;
  final Map<String, dynamic>? teacherData;
  final int studentCount;
  final bool isRegistered;

  const TeacherDetailsPage({
    Key? key,
    this.teacherDoc,
    this.teacherData,
    required this.studentCount,
    required this.isRegistered,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get teacher details from either teacherDoc or teacherData
    String name = teacherDoc?['name'] ?? teacherData?['name'] ?? 'N/A';
    String email = teacherDoc?['email'] ?? teacherData?['email'] ?? 'N/A';
    String teacherId = teacherDoc?.id ?? teacherData?['id'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Details'),
        actions: [
          if (isRegistered)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context, teacherId),
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teacher Information',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(),
                    _buildInfoRow('Name', name),
                    SizedBox(height: 10),
                    _buildInfoRow('Email', email),
                    SizedBox(height: 10),
                    _buildInfoRow('ID', teacherId),
                    SizedBox(height: 10),
                    _buildInfoRow('Status', isRegistered ? 'Registered' : 'Not Registered'),
                    if (isRegistered) ...[
                      SizedBox(height: 10),
                      _buildInfoRow('Students', studentCount.toString()),
                    ],
                  ],
                ),
              ),
            ),
            if (isRegistered) ...[
              SizedBox(height: 20),
              Text(
                'Students',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('students')
                      .where('teacherId', isEqualTo: teacherId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final students = snapshot.data?.docs ?? [];
                    
                    if (students.isEmpty) {
                      return Center(child: Text('No students found'));
                    }

                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return ListTile(
                          leading: Icon(Icons.person_outline),
                          title: Text(student['name'] ?? 'N/A'),
                          subtitle: Text('Student ID: ${student.id}'),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, String teacherId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Teacher'),
        content: Text('Are you sure you want to delete this teacher? This will also delete all associated students.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _deleteTeacher(teacherId);
        Navigator.pop(context); // Return to previous screen
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting teacher: $e')),
        );
      }
    }
  }

  Future<void> _deleteTeacher(String teacherId) async {
    final batch = FirebaseFirestore.instance.batch();
    
    // Delete all students of this teacher
    final students = await FirebaseFirestore.instance
        .collection('students')
        .where('teacherId', isEqualTo: teacherId)
        .get();
    
    for (var doc in students.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete the teacher
    batch.delete(FirebaseFirestore.instance.collection('teachers').doc(teacherId));
    
    // Update school's teacherIds array
    // Note: You'll need to implement this part based on your data structure
    
    await batch.commit();
  }
}