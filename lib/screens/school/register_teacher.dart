import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterTeacher extends StatelessWidget {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<String?> fetchSchoolId() async {
    if (currentUser != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('schools')
          .where('email', isEqualTo: currentUser!.email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.get('schoolId');
      }
    }
    return null; 
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register Teacher')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Teacher Name'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Teacher Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            ElevatedButton(
              onPressed: () async {
                final schoolId = await fetchSchoolId();

                await FirebaseFirestore.instance.collection('users').add({
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'role': 'teacher',
                  'schoolId': schoolId,
                });

                // Clear the fields
                nameController.clear();
                emailController.clear();

                // Close the keyboard and remove focus
                FocusScope.of(context).unfocus();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Teacher registered successfully')),
                );
              },
              child: Text('Register Teacher'),
            ),
          ],
        ),
      ),
    );
  }
}
