import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class NotificationService {
  final ApiClient _client;
  final FirebaseMessaging _firebaseMessaging;

  NotificationService(this._client, this._firebaseMessaging);

  /// Obtiene el FCM token y lo registra en el backend
  Future<String?> getFCMTokenAndRegister() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await registerFCMToken(token);
      }
      return token;
    } catch (e) {
      return null;
    }
  }

  /// Registra el FCM token en el servidor
  Future<void> registerFCMToken(String token) async {
    try {
      final Map<String, dynamic> body = {
        "fcmToken": token,
      };

      final res = await _client.post(
        "${ApiConfig.baseUrl}/api/Notifications/register-token",
        body: jsonEncode(body),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode < 200 || res.statusCode >= 300) {
        // Error silencioso
      }
    } catch (e) {
      // Continuar sin notificaciones si falla
    }
  }

  /// Obtiene historial de notificaciones del servidor
  Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    try {
      final res = await _client.get(
        "${ApiConfig.baseUrl}/api/Notifications/history",
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception(
            'Error getNotificationHistory: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Configura handlers para notificaciones
  void setupNotificationHandlers({
    required Function(RemoteMessage) onMessageReceived,
    required Function(RemoteMessage) onMessageOpenedApp,
  }) {
    // Notificación recibida mientras app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      onMessageReceived(message);
    });

    // Notificación tapped mientras app está en background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onMessageOpenedApp(message);
    });
  }

  /// Solicita permisos de notificaciones (iOS)
  Future<NotificationSettings> requestPermissions() async {
    return await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }
}
