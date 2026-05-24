class UserModel {
  final String firebaseUid;
  final String namaUser;
  final String email;
  final String role;
  final bool emailVerified;

  UserModel({
    required this.firebaseUid,
    required this.namaUser,
    required this.email,
    required this.role,
    this.emailVerified = false,
  });

  // Mapping dari database Supabase ke Object Dart
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      firebaseUid: json['firebase_uid'] ?? '',
      namaUser: json['nama_user'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'petugas', // Default fallback
      emailVerified: json['email_verified'] ?? false,
    );
  }

  // Mapping dari Object Dart ke database Supabase
  Map<String, dynamic> toJson() {
    return {
      'firebase_uid': firebaseUid,
      'nama_user': namaUser,
      'email': email,
      'role': role,
      'email_verified': emailVerified,
    };
  }
} 