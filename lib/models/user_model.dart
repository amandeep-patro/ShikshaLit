class UserModel {
  final String uid;
  final String email;
  final String role;
  final String? name;
  final String? location;
  final String? schoolId;

  UserModel({required this.uid, required this.email, required this.role, this.name, this.location, this.schoolId});

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'],
      role: data['role'],
      name: data['name'],
      location: data['location'],
      schoolId: data['schoolId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'name': name,
      'location': location,
      'schoolId': schoolId,
    };
  }
}
