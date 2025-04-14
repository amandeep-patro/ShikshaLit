import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/id_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Login method
  Future<Map<String, dynamic>> loginWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      // Admin login check
      if (email == dotenv.env['ADMIN_EMAIL'] &&
          password == dotenv.env['ADMIN_PASSWORD']) {
        return {'user': null, 'role': 'admin'};
      }

      // Regular user login
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final role = await getUserRole(result.user!.email!);
      if (role == null) throw 'User role not found';

      return {'user': result.user, 'role': role};
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    // Add your authentication logic here
    print('Signing in with email: $email and password: $password');
    // Simulate a delay for authentication
    await Future.delayed(Duration(seconds: 2));
  }

  // Future<User?> registerUser({
  //   required String email,
  //   required String password,
  //   required String role,
  //   required String name,
  //   required String schoolId,
  // }) async {
  //   try {
  //     final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  //       email: email,
  //       password: password,
  //     );

  //     final user = userCredential.user;
  //     if (user != null) {
  //       await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
  //         'email': email,
  //         'role': role,
  //         'name': name,
  //         'schoolId': schoolId,
  //       });
  //     }
  //     return user;
  //   } catch (e) {
  //     throw Exception('Registration failed: $e');
  //   }
  // }

  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  Future<String?> getUserRole(String email) async {
    try {
      // Check collections in order of hierarchy
      var schoolDoc =
          await _db
              .collection('schools')
              .where('email', isEqualTo: email.trim())
              .limit(1)
              .get();
      if (schoolDoc.docs.isNotEmpty) return 'school';

      var teacherDoc =
          await _db
              .collection('teachers')
              .where('email', isEqualTo: email.trim())
              .limit(1)
              .get();
      if (teacherDoc.docs.isNotEmpty) return 'teacher';

      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  String _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Wrong password';
        case 'email-already-in-use':
          return 'Email already registered';
        case 'invalid-email':
          return 'Invalid email format';
        default:
          return e.message ?? 'Authentication failed';
      }
    }
    return e.toString();
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // School Registration
  Future<User?> registerSchool({
    required String email,
    required String password,
    required String name,
    required String location,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String schoolId = IdService.generateSchoolId();

      await _db.collection('schools').doc(schoolId).set({
        'email': email,
        'name': name,
        'location': location,
        'role': 'school',
        'schoolId': schoolId,
        'teacherIds': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      return cred.user;
    } catch (e) {
      rethrow;
    }
  }

  //! Teacher Registration
  Future<User?> registerTeacher({
  required String email,
  required String password,
  required String name,
  required String schoolId,
}) async {
  try {
    DocumentSnapshot schoolDoc =
        await _db.collection('schools').doc(schoolId).get();
    if (!schoolDoc.exists) {
      throw 'School not found';
    }
    
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String teacherId = IdService.generateTeacherId();

      await _db.collection('teachers').doc(teacherId).set({
        'email': email,
        'name': name,
        'role': 'teacher',
        'schoolId': schoolId,
        'teacherId': teacherId,
        'studentIds': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('schools').doc(schoolId).update({
        'teacherIds': FieldValue.arrayUnion([teacherId]),
      });

      await _db.collection('users').doc(querySnapshot.docs[0].id).delete();

      return cred.user;
    } else {
      throw ArgumentError('You are not registered by any school.');
    }
  } catch (e) {
    rethrow;
  }
}


  // Student Registration
  Future<void> registerStudent({
    required String name,
    required String teacherId,
    required String schoolId,
  }) async {
    try {
      String studentId = IdService.generateStudentId();

      await _db.collection('students').doc(studentId).set({
        'name': name,
        'teacherId': teacherId,
        'schoolId': schoolId,
        'studentId': studentId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('teachers').doc(teacherId).update({
        'studentIds': FieldValue.arrayUnion([studentId]),
      });
    } catch (e) {
      rethrow;
    }
  }
}
