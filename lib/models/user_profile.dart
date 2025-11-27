
import 'enums.dart';

class UserProfile {
  final int id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;
  final String? bio;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String? address;
  final double? basePrice;
  final bool isBanned;
  final bool isSuspended;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.bio,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.address,
    this.basePrice,
    required this.isBanned,
    required this.isSuspended,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: UserRole.values[json['role'] ?? 0],
      phone: json['phone'],
      bio: json['bio'],
      imageUrl: json['imageUrl'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'],
      basePrice: (json['basePrice'] as num?)?.toDouble(),
      isBanned: json['isBanned'] ?? false,
      isSuspended: json['isSuspended'] ?? false,
    );
  }
}
