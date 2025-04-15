import 'package:flutter/material.dart';
import 'package:literacy_check/auth_service.dart';
import 'package:literacy_check/screens/admin/admin_dashboard_page.dart';
import 'package:literacy_check/screens/role_selection.dart';
import 'package:literacy_check/services/user_preferences.dart';


class AdminHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () async {
              await UserPreferences.clearLoginState();
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
                  MaterialPageRoute(builder: (context) => AdminDashboard()),
                );
              },
              child: Card(
                elevation: 4,
                child: ListTile(
                  leading: Icon(Icons.dashboard, color: Colors.purple),
                  title: Text("Dashboard"),
                  subtitle: Text("View progress and analytics"),
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