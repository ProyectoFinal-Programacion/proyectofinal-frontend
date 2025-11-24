import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// mobile only
import 'dart:io' as io;
// web only
import 'dart:html' as html;

import '../config/api_config.dart';
import 'api_client.dart';

class UploadsService {
  final ApiClient _client;
  UploadsService(this._client);

  // ============================================================
  //  AVATAR UPLOAD
  // ============================================================

  Future<String> uploadAvatar() async {
    if (kIsWeb) {
      return _uploadAvatarWeb();
    } else {
      throw Exception("En móvil usar uploadAvatarMobile(filePath)");
    }
  }

  Future<String> _uploadAvatarWeb() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;

    final file = input.files!.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;

    final bytes = reader.result as Uint8List;

    final uri =
        Uri.parse("${ApiConfig.baseUrl}${ApiConfig.users}/me/avatar");

    final req = http.MultipartRequest("POST", uri);

    final token = await _client.getToken();
    if (token != null) {
      req.headers["Authorization"] = "Bearer $token";
    }

    req.files.add(
      http.MultipartFile.fromBytes(
        "file",
        bytes,
        filename: file.name,
      ),
    );

    final res = await req.send();
    final body = await res.stream.bytesToString();

    return _extractSingleImageUrl(body);
  }

  Future<String> uploadAvatarMobile(String filePath) async {
    final file = io.File(filePath);
    final res = await _client.uploadFile(
      "${ApiConfig.users}/me/avatar",
      fieldName: "file",
      file: file,
    );

    final body = await res.stream.bytesToString();
    return _extractSingleImageUrl(body);
  }

  // ============================================================
  //  CHAT IMAGE UPLOAD
  // ============================================================

  Future<String> uploadChatImage({
    required int conversationId,
    required dynamic file,
  }) async {
    if (kIsWeb) {
      return _uploadChatImageWeb(conversationId);
    } else {
      return _uploadChatImageMobile(conversationId, file as io.File);
    }
  }

  Future<String> _uploadChatImageWeb(int conversationId) async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;

    final file = input.files!.first;

    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;

    final bytes = reader.result as Uint8List;

    final uri =
        Uri.parse("${ApiConfig.baseUrl}${ApiConfig.uploads}/chat");

    final req = http.MultipartRequest("POST", uri);

    final token = await _client.getToken();
    if (token != null) {
      req.headers["Authorization"] = "Bearer $token";
    }

    req.fields["conversationId"] = conversationId.toString();

    req.files.add(
      http.MultipartFile.fromBytes(
        "file",
        bytes,
        filename: file.name,
      ),
    );

    final res = await req.send();
    final body = await res.stream.bytesToString();

    return _extractChatResponse(body);
  }

  Future<String> _uploadChatImageMobile(
      int conversationId, io.File file) async {
    final res = await _client.uploadFile(
      "${ApiConfig.uploads}/chat",
      fieldName: "file",
      file: file,
      fields: {"conversationId": conversationId.toString()},
    );

    final body = await res.stream.bytesToString();
    return _extractChatResponse(body);
  }

  // ============================================================
  //  GIG IMAGE UPLOAD — CORREGIDO
  // ============================================================

  Future<String> uploadGigImage(int gigId, dynamic file) async {
    if (kIsWeb) {
      return _uploadGigImageWeb(gigId, file as Uint8List);
    } else {
      return _uploadGigImageMobile(gigId, file as io.File);
    }
  }

  Future<String> _uploadGigImageMobile(int gigId, io.File file) async {
    final res = await _client.uploadFile(
      "${ApiConfig.gigs}/$gigId/image",
      fieldName: "file",
      file: file,
    );

    final body = await res.stream.bytesToString();
    return _extractGigImageFromResponse(body);
  }

  Future<String> _uploadGigImageWeb(int gigId, Uint8List bytes) async {
    final uri =
        Uri.parse("${ApiConfig.baseUrl}${ApiConfig.gigs}/$gigId/image");

    final req = http.MultipartRequest("POST", uri);

    final token = await _client.getToken();
    if (token != null) {
      req.headers["Authorization"] = "Bearer $token";
    }

    req.files.add(
      http.MultipartFile.fromBytes(
        "file",
        bytes,
        filename: "gig-image.png",
      ),
    );

    final res = await req.send();
    final body = await res.stream.bytesToString();

    return _extractGigImageFromResponse(body);
  }

  // ============================================================
  //  JSON RESPONSE PARSERS — CORREGIDOS
  // ============================================================

  String _extractSingleImageUrl(String body) {
    if (body.isEmpty) return "";

    try {
      final json = jsonDecode(body);

      if (json is Map) {
        final raw = json["imageUrl"] ?? json["url"];
        if (raw != null) {
          return raw.toString().replaceAll("\\", "/");
        }
      }
    } catch (_) {}

    return "";
  }

  String _extractChatResponse(String body) {
    if (body.isEmpty) return "";

    try {
      final json = jsonDecode(body);
      if (json is String) return json;
      return json.toString();
    } catch (_) {
      return body;
    }
  }

  // 🔥🔥🔥 FIX CRÍTICO AQUÍ
  String _extractGigImageFromResponse(String body) {
    if (body.isEmpty) return "";

    try {
      final json = jsonDecode(body);

      if (json is Map<String, dynamic>) {
        // Caso 1: lista de imágenes devuelta por backend
        if (json["imageUrls"] is List && json["imageUrls"].isNotEmpty) {
          final raw = json["imageUrls"].last.toString();
          return raw.replaceAll("\\", "/");
        }

        // Caso 2: backend devuelve solo una imagen
        if (json["imageUrl"] != null) {
          return json["imageUrl"].toString().replaceAll("\\", "/");
        }
      }
    } catch (_) {}

    return "";
  }
}
