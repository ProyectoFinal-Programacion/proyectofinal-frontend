import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_response.dart';
import '../models/enums.dart';
import '../models/user_profile.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/local_notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _client;
  AuthProvider(this._client);

  bool isLoading = true;
  String? _token;
  UserProfile? user;

  bool get isAuthenticated => _token != null && user != null;

  // ============================================================
  // CARGAR DESDE STORAGE
  // ============================================================
  Future<void> loadFromStorage() async {
    isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('auth_token');

    if (storedToken != null) {
      _token = storedToken;

      _client.setToken(storedToken);

      try {
        user = await UserService(_client).getMe();
      } catch (e) {
        // Token inválido → limpiar
        _token = null;
        user = null;
        await prefs.remove('auth_token');
      }
    }

    isLoading = false;
    notifyListeners();
  }

  // ============================================================
  // LOGIN
  // ============================================================
  Future<void> login(String email, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      final authService = AuthService(_client);
      final AuthResponse res = await authService.login(email, password);

      _token = res.token;
      user = res.user;

      // Guardar token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);

      await _client.setToken(_token!);

      // Registrar FCM token después de login exitoso
      _setupNotifications();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow; // dejar que la UI muestre el error
    }

    isLoading = false;
    notifyListeners();
  }

  // ============================================================
  // REGISTER
  // ============================================================
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final authService = AuthService(_client);
      final AuthResponse res = await authService.register(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
      );

      _token = res.token;
      user = res.user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);

      await _client.setToken(_token!);
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }

    isLoading = false;
    notifyListeners();
  }

  // ============================================================
  // REFRESCAR PERFIL
  // ============================================================
  Future<void> refreshProfile() async {
    final service = UserService(_client);
    user = await service.getMe();
    notifyListeners();
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> logout() async {
    _token = null;
    user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    await _client.clearToken();

    notifyListeners();
  }

  // ============================================================
  // CONFIGURAR NOTIFICACIONES
  // ============================================================
  Future<void> _setupNotifications() async {
    try {
      // Inicializar notificaciones locales
      LocalNotificationService().initialize();

      // Obtener y registrar FCM token
      // Nota: firebase_messaging requiere configuración de Firebase
      // que se debe hacer en main.dart antes de inicializar el app
    } catch (e) {
      // Silenciar errores de notificaciones
    }
  }
}
