import 'package:flutter/material.dart';
import 'package:literacy_check/auth_service.dart';
import 'package:literacy_check/screens/role_selection.dart';
import 'package:literacy_check/screens/school/about_school_page.dart';
import 'package:literacy_check/screens/school/teacher_management_page.dart';

class SchoolHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('School Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AboutSchool()),
              );
            },
            tooltip: 'About School',
          ),
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
                  MaterialPageRoute(builder: (context) => TeacherManagementPage()),
                );
              },
              child: Card(
                elevation: 4,
                child: ListTile(
                  leading: Icon(Icons.person, color: Colors.blue),
                  title: Text("Teachers"),
                  subtitle: Text("Manage teachers registered by your school"),
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
