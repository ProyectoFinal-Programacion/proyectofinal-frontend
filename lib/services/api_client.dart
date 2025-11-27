import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final String baseUrl;
  String? _token;

  ApiClient({required this.baseUrl});

  Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  // ============================================================
  // TOKEN
  // ============================================================

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await _prefs;
    await prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await _prefs;
    _token = prefs.getString('auth_token');
    return _token;
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await _prefs;
    await prefs.remove('auth_token');
  }

  // ============================================================
  // HEADERS
  // ============================================================

  Future<Map<String, String>> _headers({
    Map<String, String>? extra,
    bool json = true,
  }) async {
    final token = await getToken();

    final base = <String, String>{};

    // Solo agregar content-type si realmente es JSON
    if (json) {
      base[HttpHeaders.contentTypeHeader] = 'application/json';
    }

    if (token != null) {
      base[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }

    if (extra != null) {
      extra.remove(HttpHeaders.contentTypeHeader); // ❗ evitar duplicado
      base.addAll(extra);
    }

    return base;
  }

  // ============================================================
  // URL
  // ============================================================

  Uri _buildUri(String path) {
    path = path.replaceAll('\\', '/');

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }

    if (path.startsWith('/')) {
      return Uri.parse('$baseUrl$path');
    }

    return Uri.parse('$baseUrl/$path');
  }

  // ============================================================
  // GET
  // ============================================================

  Future<http.Response> get(String path) async {
    final uri = _buildUri(path);
    final headers = await _headers();
    return http.get(uri, headers: headers);
  }

  // ============================================================
  // POST
  // ============================================================

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = _buildUri(path);
    final mergedHeaders = await _headers(extra: headers);

    // evitar double-encoding
    final encoded = body is Map
        ? jsonEncode(body)
        : body; // si ya es string, lo deja igual

    return http.post(uri, headers: mergedHeaders, body: encoded);
  }

  // ============================================================
  // PUT
  // ============================================================

  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = _buildUri(path);
    final mergedHeaders = await _headers(extra: headers);

    final encoded =
        (body is Map) ? jsonEncode(body) : body;

    return http.put(uri, headers: mergedHeaders, body: encoded);
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<http.Response> delete(String path) async {
    final uri = _buildUri(path);
    final headers = await _headers();
    return http.delete(uri, headers: headers);
  }

  // ============================================================
  // UPLOAD FILE
  // ============================================================

  Future<http.StreamedResponse> uploadFile(
    String path, {
    required String fieldName,
    required File file,
    Map<String, String>? fields,
  }) async {
    final uri = _buildUri(path);

    final req = http.MultipartRequest('POST', uri);

    final token = await getToken();
    if (token != null) {
      req.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }

    if (fields != null) req.fields.addAll(fields);

    req.files.add(
      await http.MultipartFile.fromPath(fieldName, file.path),
    );

    return req.send();
  }
}
