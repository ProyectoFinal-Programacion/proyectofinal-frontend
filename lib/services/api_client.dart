import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  // Base URL configurada al servidor proporcionado por el usuario:
  static const String baseUrl = 'https://app-251110212719.azurewebsites.net';
  final SecureStorageService storage;
  ApiClient({required this.storage});

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await storage.getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _u(String path, [Map<String, dynamic>? q]) {
    final uri = Uri.parse('$baseUrl$path');
    if (q == null) return uri;
    return uri.replace(queryParameters: {for (final e in q.entries) e.key: e.value.toString()});
  }

  // -------- Auth --------
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(_u('/api/auth/login'), headers: await _headers(), body: jsonEncode({'email': email, 'password': password}));
    final data = _decode(res);
    if (res.statusCode == 200) return data;
    throw ApiException(data['message'] ?? 'Login failed', statusCode: res.statusCode);
  }

  Future<Map<String, dynamic>> register(String name, String email, String password, String role) async {
    final res = await http.post(_u('/api/auth/register'), headers: await _headers(), body: jsonEncode({'name': name, 'email': email, 'password': password, 'role': role}));
    final data = _decode(res);
    if (res.statusCode == 200) return data;
    throw ApiException(data['message'] ?? 'Register failed', statusCode: res.statusCode);
  }

  // -------- Services --------
  Future<List<dynamic>> listServices() async {
    final res = await http.get(_u('/api/services'), headers: await _headers());
    final data = _decode(res);
    if (res.statusCode == 200) return data as List;
    throw ApiException('Failed to fetch services', statusCode: res.statusCode);
  }

  Future<Map<String, dynamic>> getService(int id) async {
    final res = await http.get(_u('/api/services/$id'), headers: await _headers());
    final data = _decode(res);
    if (res.statusCode == 200) return data;
    throw ApiException('Failed to fetch service', statusCode: res.statusCode);
  }

  Future<Map<String, dynamic>> createService({required String name, required String description, required String category}) async {
    final res = await http.post(_u('/api/services'), headers: await _headers(auth: true), body: jsonEncode({'name': name, 'description': description, 'category': category}));
    final data = _decode(res);
    if (res.statusCode == 201) return data;
    throw ApiException(data['message'] ?? 'Failed to create service', statusCode: res.statusCode);
  }

  // -------- Workers --------
  Future<List<dynamic>> listWorkers() async {
    final res = await http.get(_u('/api/workers'), headers: await _headers());
    final data = _decode(res);
    if (res.statusCode == 200) return data as List;
    throw ApiException('Failed to fetch workers', statusCode: res.statusCode);
  }

  Future<Map<String, dynamic>> getWorker(int id) async {
    final res = await http.get(_u('/api/workers/$id'), headers: await _headers());
    final data = _decode(res);
    if (res.statusCode == 200) return data;
    throw ApiException('Failed to fetch worker', statusCode: res.statusCode);
  }

  Future<Map<String, dynamic>> workerWhatsAppLink(int id, String message) async {
    final res = await http.get(_u('/api/workers/$id/whatsapp-link', {'message': message}), headers: await _headers());
    final data = _decode(res);
    if (res.statusCode == 200) return data;
    throw ApiException('Failed to get whatsapp link', statusCode: res.statusCode);
  }

  Future<Map<String, dynamic>> createWorkerProfile({
    required String trade,
    required String zone,
    required String bio,
    String availability = 'Disponible',
    String? photoUrl,
    String? galleryUrls,
    String? phoneNumber,
  }) async {
    final body = {
      'trade': trade,
      'zone': zone,
      'bio': bio,
      'availability': availability,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (galleryUrls != null) 'galleryUrls': galleryUrls,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
    final res = await http.post(_u('/api/workers'), headers: await _headers(auth: true), body: jsonEncode(body));
    final data = _decode(res);
    if (res.statusCode == 201 || res.statusCode == 200) return data;
    throw ApiException(data['message'] ?? 'Failed to create worker profile', statusCode: res.statusCode);
  }

  Future<Map<String, dynamic>> updateWorkerProfile(int id, Map<String, dynamic> patch) async {
    final res = await http.put(_u('/api/workers/$id'), headers: await _headers(auth: true), body: jsonEncode(patch));
    final data = _decode(res);
    if (res.statusCode == 200) return data;
    throw ApiException(data['message'] ?? 'Failed to update worker profile', statusCode: res.statusCode);
  }

  // -------- Requests (auth) --------
  Future<List<dynamic>> listRequests() async {
    final res = await http.get(_u('/api/requests'), headers: await _headers(auth: true));
    final data = _decode(res);
    if (res.statusCode == 200) return data as List;
    throw ApiException('Failed to fetch requests', statusCode: res.statusCode);
  }

  Future<Map<String, dynamic>> createRequest({required int workerId, required int serviceId, DateTime? date}) async {
    final body = {'workerId': workerId, 'serviceId': serviceId, if (date != null) 'dateRequested': date.toUtc().toIso8601String()};
    final res = await http.post(_u('/api/requests'), headers: await _headers(auth: true), body: jsonEncode(body));
    final data = _decode(res);
    if (res.statusCode == 201) return data;
    throw ApiException(data['message'] ?? 'Failed to create request', statusCode: res.statusCode);
  }

  Future<Map<String, dynamic>> updateRequestStatus(int id, String status) async {
    final res = await http.patch(_u('/api/requests/$id/status'), headers: await _headers(auth: true), body: jsonEncode({'status': status}));
    final data = _decode(res);
    if (res.statusCode == 200) return data;
    throw ApiException(data['message'] ?? 'Failed to update status', statusCode: res.statusCode);
  }

  // -------- Reviews --------
  Future<List<dynamic>> reviewsForWorker(int workerId) async {
    final res = await http.get(_u('/api/reviews/worker/$workerId'), headers: await _headers());
    final data = _decode(res);
    if (res.statusCode == 200) return data as List;
    throw ApiException('Failed to fetch reviews', statusCode: res.statusCode);
  }

  Future<Map<String, dynamic>> createReview({required int workerId, required int rating, required String comment}) async {
    final res = await http.post(_u('/api/reviews'), headers: await _headers(auth: true), body: jsonEncode({'workerId': workerId, 'rating': rating, 'comment': comment}));
    final data = _decode(res);
    if (res.statusCode == 200) return data;
    throw ApiException(data['message'] ?? 'Failed to create review', statusCode: res.statusCode);
  }

  // -------- Admin (optional) --------
  Future<List<dynamic>> adminListUsers() async {
    final res = await http.get(_u('/api/users'), headers: await _headers(auth: true));
    final data = _decode(res);
    if (res.statusCode == 200) return data as List;
    throw ApiException('Failed to fetch users', statusCode: res.statusCode);
  }

  // helper
  dynamic _decode(http.Response res) {
    if (res.body.isEmpty) return {};
    try { return jsonDecode(res.body); } catch (_) { return {'raw': res.body}; }
  }
}
