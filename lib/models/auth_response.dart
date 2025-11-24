
import 'user_profile.dart';

class AuthResponse {
  final String token;
  final DateTime expiresAt;
  final UserProfile user;

  AuthResponse({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      expiresAt: DateTime.parse(json['expiresAt']),
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
