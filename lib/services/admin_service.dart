
import 'dart:convert';

import '../config/api_config.dart';
import 'api_client.dart';

import '../models/order.dart';

class AdminService {
  final ApiClient _client;
  AdminService(this._client);

  Future<List<dynamic>> getUsers() async {
    final res = await _client.get('${ApiConfig.admin}/users');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as List<dynamic>;
      return json;
    } else {
      throw Exception('Error getUsers: ${res.statusCode}');
    }
  }

  Future<List<Order>> getAllOrders() async {
    final res = await _client.get('${ApiConfig.admin}/orders');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => Order.fromJson(e)).toList();
    } else {
      // Si falla el endpoint específico de admin, intentamos el genérico si el usuario es admin
      // Pero por ahora asumimos que existe /api/Admin/orders
      throw Exception('Error getAllOrders: ${res.statusCode}');
    }
  }

  Future<void> banUser(int id) async {
    final res = await _client.put('${ApiConfig.admin}/users/$id/ban');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Error banUser: ${res.statusCode}');
    }
  }

  Future<void> unbanUser(int id) async {
    final res = await _client.put('${ApiConfig.admin}/users/$id/unban');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Error unbanUser: ${res.statusCode}');
    }
  }

  Future<void> deleteUser(int id) async {
    final res = await _client.delete('${ApiConfig.admin}/users/$id');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Error deleteUser: ${res.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _client.get('${ApiConfig.admin}/dashboard');
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json;
    } else {
      throw Exception('Error dashboard: ${res.statusCode}');
    }
  }
}
