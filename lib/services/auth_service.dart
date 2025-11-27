import 'dart:convert';
import '../config/api_config.dart';
import '../models/auth_response.dart';
import '../models/enums.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client;
  AuthService(this._client);

  // ===========================================================
  // LOGIN
  // ===========================================================
  Future<AuthResponse> login(String email, String password) async {
    final body = jsonEncode({
      'email': email,
      'password': password,
    });

    final res = await _client.post(
      '${ApiConfig.auth}/login',
      body: body,
      headers: {"Content-Type": "application/json"},
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body);
      return AuthResponse.fromJson(json);
    } else {
      throw Exception('Error login: ${res.statusCode} - ${res.body}');
    }
  }

  // ===========================================================
  // REGISTER
  // ===========================================================
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    final body = jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'role': role.index,
      'phone': phone,
    });

    final res = await _client.post(
      '${ApiConfig.auth}/register',
      body: body,
      headers: {"Content-Type": "application/json"},
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body);
      return AuthResponse.fromJson(json);
    } else {
      throw Exception('Error register: ${res.statusCode} - ${res.body}');
    }
  }
}
