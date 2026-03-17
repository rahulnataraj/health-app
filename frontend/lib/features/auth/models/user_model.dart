class UserModel {
  final String id;
  final String email;
  final String username;
  final String? role;
  final String? patientId;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.role,
    this.patientId,
  });

  factory UserModel.fromLoginResponse(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      role: json['role'] as String?,
    );
  }

  factory UserModel.fromMeResponse(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      role: json['role'] as String?,
      patientId: json['patient_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'email': email,
      'username': username,
      'role': role,
      'patient_id': patientId,
    };
  }
}
