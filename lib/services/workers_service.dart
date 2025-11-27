import 'dart:convert';
import '../config/api_config.dart';
import '../models/worker_search_result.dart';
import 'api_client.dart';

class WorkersService {
  final ApiClient _client;
  WorkersService(this._client);

  Future<List<WorkerSearchResult>> searchWorkers({
    required double lat,
    required double lon,
    double radiusKm = 10,
  }) async {
    final url =
        '${ApiConfig.baseUrl}${ApiConfig.workers}/search?lat=$lat&lon=$lon&radiusKm=$radiusKm';

    final res = await _client.get(url);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => WorkerSearchResult.fromJson(e)).toList();
    } else {
      throw Exception("Error buscando trabajadores: ${res.statusCode}");
    }
  }
}
