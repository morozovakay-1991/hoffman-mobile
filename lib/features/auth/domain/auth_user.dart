import 'package:flutter/foundation.dart';

/// Signed-in user, as returned in `user` by `/auth/login`, `/auth/register`
/// and `/auth/me` (backend `UserResource`).
@immutable
class AuthUser {
  const AuthUser({required this.id, required this.name, required this.email});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String,
    );
  }

  final int id;
  final String name;
  final String email;

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.id == id &&
      other.name == name &&
      other.email == email;

  @override
  int get hashCode => Object.hash(id, name, email);
}
