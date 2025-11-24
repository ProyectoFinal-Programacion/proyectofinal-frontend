import 'dart:convert';
import '../config/api_config.dart';
import '../models/enums.dart';
import '../models/order.dart';
import 'api_client.dart';

class OrdersService {
  final ApiClient _client;
  OrdersService(this._client);

  // ============================================================
  // CREATE ORDER (COMPATIBLE CON SWAGGER)
  // ============================================================

  Future<void> createOrder({
    required int workerId,
    required int gigId,
    required String description,
    required String address,
    required double totalPrice,
    double? latitude,
    double? longitude,
  }) async {
    final Map<String, dynamic> data = {
      "workerId": workerId,
      "gigId": gigId,
      "description": description,
      "address": address,
      "totalPrice": totalPrice,
      "latitude": latitude,
      "longitude": longitude,
    };

    final res = await _client.post(
      ApiConfig.orders,
      body: data,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Error createOrder: ${res.statusCode}");
    }
  }

  // ============================================================
  // GET MY ORDERS (CLIENTE)
  // ============================================================

  Future<List<Order>> getMyOrders() async {
    final res = await _client.get("${ApiConfig.orders}/my");

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Error getMyOrders: ${res.statusCode}");
    }

    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Order.fromJson(e)).toList();
  }

  // ============================================================
  // GET RECEIVED ORDERS (WORKER)
  // ============================================================

  Future<List<Order>> getReceivedOrders() async {
    final res = await _client.get("${ApiConfig.orders}/received");

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Error getReceivedOrders: ${res.statusCode}");
    }

    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => Order.fromJson(e)).toList();
  }

  // ============================================================
  // UPDATE ORDER STATUS (PUT /Orders/{id}/status?status=1)
  // ============================================================

  Future<void> updateStatus(int id, OrderStatus status) async {
    final res = await _client.put(
      "${ApiConfig.orders}/$id/status?status=${status.index}",
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Error updateStatus: ${res.statusCode}");
    }
  }
}
