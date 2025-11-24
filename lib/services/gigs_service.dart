import 'dart:convert';
import '../config/api_config.dart';
import '../models/gig.dart';
import 'api_client.dart';

class GigsService {
  final ApiClient _client;
  GigsService(this._client);

  // ============================================================
  //  GET SINGLE GIG (Necesario para refrescar datos correctos)
  // ============================================================

  Future<Gig> getGig(int id) async {
    final res = await _client.get('${ApiConfig.gigs}/$id');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) throw Exception("Gig vacío del backend");
      return Gig.fromJson(jsonDecode(res.body));
    }

    throw Exception("Error getGig: ${res.statusCode}");
  }

  // ============================================================
  //  LISTA DE GIGS
  // ============================================================

  Future<List<Gig>> getGigs({String? category}) async {
    final query =
        (category != null && category.isNotEmpty) ? '?category=$category' : '';

    final res = await _client.get('${ApiConfig.gigs}$query');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return [];
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => Gig.fromJson(e)).toList();
    }

    throw Exception('Error getGigs: ${res.statusCode}');
  }

  // ============================================================
  //  GET GIGS BY WORKER
  // ============================================================

  Future<List<Gig>> getWorkerGigs(int workerId) async {
    final res = await _client.get('${ApiConfig.gigs}/worker/$workerId');

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return [];
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => Gig.fromJson(e)).toList();
    }

    throw Exception('Error getWorkerGigs: ${res.statusCode}');
  }

  // ============================================================
  //  CREATE GIG
  // ============================================================

  Future<Gig> createGig({
    required String title,
    String? description,
    String? category,
    required double price,
  }) async {
    final body = {
      'title': title,
      'description': description,
      'category': category,
      'price': price,
    };

    final res = await _client.post(ApiConfig.gigs, body: body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      if (res.body.isEmpty) {
        throw Exception("Backend devolvió vacío al crear gig");
      }
      return Gig.fromJson(jsonDecode(res.body));
    }

    throw Exception("Error createGig: ${res.statusCode}");
  }

  // ============================================================
  //  UPDATE GIG — FIX COMPLETO PARA AZURE
  // ============================================================

  Future<Gig> updateGig(
    int id, {
    required String title,
    String? description,
    String? category,
    required double price,
  }) async {
    final body = {
      'title': title,
      'description': description,
      'category': category,
      'price': price,
    };

    // 🔥 Azure App Service REQUIERE PUT REAL
    final res = await _client.put('${ApiConfig.gigs}/$id', body: body);

    // Azure devuelve 204 No Content
    if (res.statusCode == 204) {
      // 🔥 Solución definitiva: recargar el gig desde el backend
      return await getGig(id);
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) {
        return await getGig(id);
      }
      return Gig.fromJson(jsonDecode(res.body));
    }

    throw Exception("Error updateGig: ${res.statusCode}");
  }

  // ============================================================
  //  DELETE GIG
  // ============================================================

  Future<void> deleteGig(int id) async {
    final res = await _client.delete('${ApiConfig.gigs}/$id');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Error deleteGig: ${res.statusCode}");
    }
  }
}
