import 'package:flutter/material.dart';
import 'package:literacy_check/auth_service.dart';
import 'package:literacy_check/screens/role_selection.dart';

class StudentHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Student Practice'),
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
      body: Center(child: Text('Student can practice assessments here.')),
    );
  }
}