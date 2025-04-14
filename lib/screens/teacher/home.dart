import 'package:flutter/material.dart';
import 'package:literacy_check/auth_service.dart';
import 'package:literacy_check/screens/role_selection.dart';
import 'package:literacy_check/screens/teacher/student_list_page.dart';

class TeacherHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              await AuthService().signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => RoleSelection()),
                (route) => false,
              );
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StudentListPage()),
                );
              },
              child: Card(
                elevation: 4,
                child: ListTile(
                  leading: Icon(Icons.group, color: Colors.blue),
                  title: Text("Students"),
                  subtitle: Text("View and manage students under this teacher"),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}