import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:literacy_check/screens/splash_screen.dart';
import 'package:literacy_check/services/user_preferences.dart';
import '../auth_service.dart';
import '../utils/navigation.dart';

class AuthWrapper extends StatelessWidget {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: UserPreferences.getLoginState(),
      builder: (context, prefsSnapshot) {
        if (prefsSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        final loginState = prefsSnapshot.data;
        if (loginState != null && loginState['isLoggedIn'] == true) {
          // If admin credentials are stored, return admin home
          if (loginState['role'] == 'admin') {
            return AppNavigation.getHomeByRole('admin');
          }

          // For other roles, use Firebase auth state
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }

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

              // If user is not authenticated, check stored credentials
              if (loginState['isLoggedIn'] == true && loginState['role'] != null) {
                return AppNavigation.getHomeByRole(loginState['role']);
              }

              // If no stored credentials, show login
              return SplashScreen();
            },
          );
        }

        // If no stored login state, show splash screen
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
