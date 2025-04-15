import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class SchoolDashboard extends StatefulWidget {
  const SchoolDashboard({super.key});
  @override
  State<SchoolDashboard> createState() => _SchoolDashboardState();
}

class _SchoolDashboardState extends State<SchoolDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? schoolData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchoolData();
  }

  Future<void> _loadSchoolData() async {
    try {
      setState(() => isLoading = true);

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final schoolQuery =
          await _firestore
              .collection('schools')
              .where('email', isEqualTo: currentUser.email)
              .limit(1)
              .get();

      if (schoolQuery.docs.isNotEmpty) {
        final schoolDoc = schoolQuery.docs.first;
        final data = schoolDoc.data();

        setState(() {
          schoolData = {
            'schoolId': data['schoolId'] ?? '',
            'name': data['name'] ?? 'Not set',
            'email': data['email'] ?? '',
            'role': data['role'] ?? 'Not set',
            'location': data['location'] ?? '',
            'teacherIds': data['teacherIds'] ?? [],
            'createdAt': data['createdAt']?.toDate().toString() ?? 'Not set',
          };
        });
      } else {
        print('No school found with email: ${currentUser.email}');
      }
     
    } catch (e) {
      print('Error loading school data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('School Dashboard')),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : schoolData == null
              ? Center(child: Text('No school data found'))
              : SingleChildScrollView(
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
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            SizedBox(height: 16),
                            _buildInfoRow(
                              'School ID',
                              schoolData!['schoolId'],
                            ),
                            _buildInfoRow('Name', schoolData!['name']),
                            _buildInfoRow('Email', schoolData!['email']),
                            _buildInfoRow('Role', schoolData!['role']),
                            _buildInfoRow(
                              'School ID',
                              schoolData!['schoolId'],
                            ),
                            _buildInfoRow(
                              'Created At',
                              schoolData!['createdAt'],
                            ),
                            _buildInfoRow(
                              'Teachers Assigned',
                              (schoolData!['teacherIds'] as List).length
                                  .toString(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label + ':',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}