import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AboutSchool extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About School'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _getSchoolData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading school data'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('School data not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'School Information',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Divider(),
                        _buildInfoRow('Name', data['name'] ?? 'N/A'),
                        SizedBox(height: 8),
                        _buildInfoRow('Email', data['email'] ?? 'N/A'),
                        SizedBox(height: 8),
                        _buildInfoRow('Location', data['location'] ?? 'N/A'),
                        SizedBox(height: 8),
                        _buildInfoRow('School ID', data['schoolId'] ?? 'N/A'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistics',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Divider(),
                        FutureBuilder<int>(
                          future: _getTeacherCount(data['schoolId']),
                          builder: (context, snapshot) {
                            return _buildInfoRow(
                              'Total Teachers',
                              snapshot.data?.toString() ?? 'Loading...',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  Future<DocumentSnapshot> _getSchoolData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'User not found';

    final schoolDoc = await FirebaseFirestore.instance
        .collection('schools')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (schoolDoc.docs.isEmpty) throw 'School not found';
    return schoolDoc.docs.first;
  }

  Future<int> _getTeacherCount(String schoolId) async {
    final teachers = await FirebaseFirestore.instance
        .collection('teachers')
        .where('schoolId', isEqualTo: schoolId)
        .get();
    return teachers.docs.length;
  }
}