class UserModel {
  final String uid;           // From Firebase Auth
  final String name;
  final String email;
  final String enrollment;
  final String branch;



  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.enrollment,
    required this.branch,

  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'enrollment': enrollment,
      'branch': branch,

    };
  }

  // Create Model from Firestore Document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      enrollment: map['enrollment'] ?? '',
      branch: map['branch'] ?? '',
    );
  }
}