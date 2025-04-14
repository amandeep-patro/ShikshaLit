import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyUserRole = 'userRole';

  static Future<void> setLoginState({
    required bool isLoggedIn,
    String? email,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
    if (email != null) await prefs.setString(_keyUserEmail, email);
    if (role != null) await prefs.setString(_keyUserRole, role);
  }

  static Future<Map<String, dynamic>> getLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isLoggedIn': prefs.getBool(_keyIsLoggedIn) ?? false,
      'email': prefs.getString(_keyUserEmail),
      'role': prefs.getString(_keyUserRole),
    };
  }

  static Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserRole);
  }
}