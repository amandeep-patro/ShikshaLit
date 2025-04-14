import 'package:flutter/material.dart';
import '../screens/admin/home.dart';
import '../screens/school/home.dart';
import '../screens/teacher/home.dart';

class AppNavigation {
  static Widget getHomeByRole(String role) {
    switch (role) {
      case 'admin':
        return AdminHome();
      case 'school':
        return SchoolHome();
      case 'teacher':
        return TeacherHome();
      default:
        throw 'Invalid role';
    }
  }
}