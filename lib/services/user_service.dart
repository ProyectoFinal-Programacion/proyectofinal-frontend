import 'dart:convert';

import '../config/api_config.dart';
import '../models/user_profile.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _client;
  UserService(this._client);

  // ------------------------------------------------------------
  // PERFIL PROPIO
  // ------------------------------------------------------------
  Future<UserProfile> getMe() async {
    final res = await _client.get('${ApiConfig.users}/me');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } else {
      throw Exception('Error getMe: ${res.statusCode}');
    }
  }

  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? bio,
    String? address,
    double? basePrice,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _client.put(
      '${ApiConfig.users}/me',
      body: {
        'name': name,
        'phone': phone,
        'bio': bio,
        'address': address,
        'basePrice': basePrice,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } else {
      throw Exception('Error updateProfile: ${res.statusCode}');
    }
  }

  // ------------------------------------------------------------
  // PERFIL PÚBLICO DE OTRO USUARIO (cliente, worker, etc.)
  // GET /api/Users/{id}
  // ------------------------------------------------------------
  Future<UserProfile> getUserById(int id) async {
    final res = await _client.get('${ApiConfig.users}/$id');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } else {
      throw Exception('Error getUserById: ${res.statusCode}');
    }
  }
}
