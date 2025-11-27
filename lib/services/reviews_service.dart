import 'dart:convert';

import '../config/api_config.dart';
import '../models/review.dart';
import 'api_client.dart';

class ReviewsService {
  final ApiClient _client;

  ReviewsService(this._client);

  // ============================================================
  // CREATE REVIEW (CLIENTE O TRABAJADOR)
  // ============================================================
  Future<Review> createReview({
    required int orderId,
    required int toUserId,
    required int rating,
    String? comment,
  }) async {
    final Map<String, dynamic> body = {
      "orderId": orderId,
      "toUserId": toUserId,
      "rating": rating,
      "comment": comment,
    };

    final res = await _client.post(
      ApiConfig.reviews,
      body: jsonEncode(body),
      headers: {"Content-Type": "application/json"},
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return Review.fromJson(jsonDecode(res.body));
    } else {
      throw Exception(
          "Error createReview: ${res.statusCode} - ${res.body}");
    }
  }

  // ============================================================
  // GET ALL REVIEWS FOR A USER
  // ============================================================
  Future<List<Review>> getUserReviews(int userId) async {
    final res = await _client.get("${ApiConfig.reviews}/user/$userId");

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final List<dynamic> list = jsonDecode(res.body);
      return list.map((e) => Review.fromJson(e)).toList();
    } else {
      throw Exception(
          "Error getUserReviews: ${res.statusCode} - ${res.body}");
    }
  }

  // ============================================================
  // GET AVERAGE RATING FOR A USER
  // ============================================================
  Future<double> getUserAverage(int userId) async {
    final res =
        await _client.get("${ApiConfig.reviews}/user/$userId/average");

    if (res.statusCode >= 200 && res.statusCode < 300) {
      // respuesta del API es un número en texto
      if (res.body.isEmpty) return 0;
      return double.tryParse(res.body) ?? 0;
    } else {
      throw Exception(
          "Error getUserAverage: ${res.statusCode} - ${res.body}");
    }
  }
}
