class ApiConfig {
  // Solo el dominio, sin /api
  static const String baseUrl = 'https://app-proyectofinal-progra.azurewebsites.net';

  // Endpoints como PATHS, no URLs completas
  static const String auth = '/api/Auth';
  static const String users = '/api/Users';
  static const String admin = '/api/Admin';
  static const String gigs = '/api/Gigs';
  static const String orders = '/api/Orders';
  static const String reviews = '/api/Reviews';
  static const String workers = '/api/Workers';
  static const String uploads = '/api/Uploads';

  // uploads de imágenes (usado para mostrar imágenes, no APIs)
  static const String uploadsBase = '$baseUrl/uploads';
}
