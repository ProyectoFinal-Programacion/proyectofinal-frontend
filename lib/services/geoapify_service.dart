import 'dart:convert';
import 'package:http/http.dart' as http;

class GeoapifyService {
  /// API key REAL de Geoapify (la que me pasaste)
  static const String apiKey = '7315f04b9c5840999f683b1df5ce9b1f';

  /// Devuelve la dirección formateada a partir de lat/lon
  Future<String?> reverseGeocode(double lat, double lon) async {
    final uri = Uri.parse(
      'https://api.geoapify.com/v1/geocode/reverse'
      '?lat=$lat&lon=$lon&apiKey=$apiKey',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final features = json['features'] as List<dynamic>;
    if (features.isEmpty) return null;

    final props = features.first['properties'] as Map<String, dynamic>;
    return props['formatted'] as String?;
  }
}
