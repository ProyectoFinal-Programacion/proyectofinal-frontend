import '../config/api_config.dart';

/// Construye una URL ABSOLUTA válida.
/// Ahora recibe `String` (NO nullable) para evitar errores de tipo.
String buildImageUrl(String url, {int? version}) {
  if (url.isEmpty) return '';

  String fullUrl;

  // Si ya viene como URL absoluta → no tocar
  if (url.startsWith("http://") || url.startsWith("https://")) {
    fullUrl = url;
  }
  // Si comienza con "/uploads/..."
  else if (url.startsWith("/")) {
    fullUrl = "${ApiConfig.baseUrl}$url";
  }
  // Cualquier otro caso → concatenar
  else {
    fullUrl = "${ApiConfig.baseUrl}/$url";
  }

  // anti-cache
  if (version != null) {
    fullUrl += "?v=$version";
  }

  return fullUrl;
}
