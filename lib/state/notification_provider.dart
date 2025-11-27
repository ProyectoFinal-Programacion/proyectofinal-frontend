import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [];
  
  List<AppNotification> get notifications => _notifications;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markAsRead(int notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = AppNotification(
        id: _notifications[index].id,
        title: _notifications[index].title,
        body: _notifications[index].body,
        payload: _notifications[index].payload,
        createdAt: _notifications[index].createdAt,
        isRead: true,
      );
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = AppNotification(
        id: _notifications[i].id,
        title: _notifications[i].title,
        body: _notifications[i].body,
        payload: _notifications[i].payload,
        createdAt: _notifications[i].createdAt,
        isRead: true,
      );
    }
    notifyListeners();
  }

  void clearNotification(int notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
