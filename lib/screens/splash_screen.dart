import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth_service.dart';
import 'role_selection.dart';
import 'student/home.dart';
import 'teacher/home.dart';
import 'school/home.dart';
import 'admin/home.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), () async {
      AuthService auth = Provider.of<AuthService>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;

      Widget nextPage;

      if (currentUser != null) {
        String? role = await auth.getUserRole(currentUser.uid);
        switch (role) {
          case 'student':
            nextPage = StudentHome(); break;
          case 'teacher':
            nextPage = TeacherHome(); break;
          case 'school':
            nextPage = SchoolHome(); break;
          case 'admin':
            nextPage = AdminHome(); break;
          default:
            nextPage = RoleSelection();
        }
      } else {
        nextPage = RoleSelection();
      }

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => nextPage));
    });

    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
