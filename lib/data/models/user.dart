/// BBZCloud Mobile - User Model
/// 
/// @version 0.1.0

import 'package:bbzcloud_mobil/core/constants/app_config.dart';

class User {
  final int? id;
  final String email;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    this.id,
    required this.email,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  /// Create User from database map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      email: map['email'] as String,
      role: UserRole.fromString(map['role'] as String),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Convert User to database map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'email': email,
      'role': role.value,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Check if user is a teacher
  bool get isTeacher => role == UserRole.teacher || role == UserRole.admin;

  /// Check if user is a student
  bool get isStudent => role == UserRole.student;

  /// Check if user email is from BBZ domain (teachers)
  bool get isBbzEmail => email.endsWith('@bbz-rd-eck.de');

  /// Copy with method for immutability
  User copyWith({
    int? id,
    String? email,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, role: ${role.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.email == email &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode ^ role.hashCode;
  }
}
