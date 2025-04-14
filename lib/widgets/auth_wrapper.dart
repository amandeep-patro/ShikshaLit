import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:literacy_check/screens/splash_screen.dart';
import '../auth_service.dart';
import '../utils/navigation.dart';

class AuthWrapper extends StatelessWidget {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // If user is authenticated
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<String?>(
            future: _auth.getUserRole(snapshot.data!.email!),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }

              if (roleSnapshot.hasData && roleSnapshot.data != null) {
                return AppNavigation.getHomeByRole(roleSnapshot.data!);
              }

              // If no role is found, sign out and show login
              FirebaseAuth.instance.signOut();
              return SplashScreen();
            },
          );
        }

        // If user is not authenticated, show login
        return SplashScreen();
      },
    );
  }

  // Loading screen with a smooth animation
  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Loading...',
              style: TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}
