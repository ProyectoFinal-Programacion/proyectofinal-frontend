import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

import '../config/api_config.dart';
import 'api_client.dart';

/// Servicio de subida de archivos multiplataforma
/// Para proyecto universitario - funciona en web y Android
class UploadsService {
  final ApiClient _client;
  UploadsService(this._client);

  // ============================================================
  //  AVATAR UPLOAD
  // ============================================================

  Future<String> uploadAvatar() async {
    return _uploadAvatarWeb();
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
    // Para móvil - no usado en web
    throw UnimplementedError("Usa uploadAvatar() en web");
  }

  // ============================================================
  //  CHAT IMAGE UPLOAD
  // ============================================================

  Future<String> uploadChatImage({
    required int conversationId,
    required dynamic file,
  }) async {
    return _uploadChatImageWeb(conversationId);
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

  // ============================================================
  //  GIG IMAGE UPLOAD
  // ============================================================

  Future<String> uploadGigImage(int gigId, dynamic fileOrBytes) async {
    if (kIsWeb) {
      // En web esperamos Uint8List, pero si llega File (de dart:io) intentamos manejarlo o fallamos
      if (fileOrBytes is Uint8List) {
        return _uploadGigImageWeb(gigId, fileOrBytes);
      } else {
        // Si estamos en web y nos pasan un File, probablemente sea un error de lógica en la UI para web
        // Pero para evitar crash, intentamos ver si podemos leerlo o lanzamos error
        throw Exception("En web uploadGigImage espera Uint8List");
      }
    } else {
      // En móvil esperamos File
      return _uploadGigImageMobile(gigId, fileOrBytes);
    }
  }

  Future<String> _uploadGigImageMobile(int gigId, dynamic file) async {
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
  //  JSON RESPONSE PARSERS
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

  String _extractGigImageFromResponse(String body) {
    if (body.isEmpty) return "";

    try {
      final json = jsonDecode(body);

      if (json is Map<String, dynamic>) {
        if (json["imageUrls"] is List && json["imageUrls"].isNotEmpty) {
          final raw = json["imageUrls"].last.toString();
          return raw.replaceAll("\\", "/");
        }

        if (json["imageUrl"] != null) {
          return json["imageUrl"].toString().replaceAll("\\", "/");
        }
      }
    } catch (_) {}

    return "";
  }
}
