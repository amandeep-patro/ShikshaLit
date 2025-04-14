import 'package:flutter/material.dart';
import '../../auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterStudent extends StatefulWidget {
  @override
  _RegisterStudentState createState() => _RegisterStudentState();
}

class _RegisterStudentState extends State<RegisterStudent> {
  final nameController = TextEditingController();
  final AuthService _authService = AuthService();

  Future<String?> _getCurrentTeacherInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final teacherDoc = await FirebaseFirestore.instance
          .collection('teachers')
          .where('email', isEqualTo: user.email)
          .get();
      
      if (teacherDoc.docs.isNotEmpty) {
        return teacherDoc.docs.first.id;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register Student')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Student Name'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  final teacherId = await _getCurrentTeacherInfo();
                  if (teacherId == null) {
                    throw 'Teacher information not found';
                  }

                  final teacherDoc = await FirebaseFirestore.instance
                      .collection('teachers')
                      .doc(teacherId)
                      .get();
                  
                  await _authService.registerStudent(
                    name: nameController.text.trim(),
                    teacherId: teacherId,
                    schoolId: teacherDoc['schoolId'],
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Student registered successfully')),
                  );
                  
                  nameController.clear();
                  FocusScope.of(context).unfocus();

                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              child: Text('Register Student'),
            ),
          ],
        ),
      ),
    );
  }
}