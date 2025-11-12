import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient api;
  final SecureStorageService storage;
  bool _busy = false;
  bool get busy => _busy;
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  String? _role;
  String? get role => _role;
  String? _name;
  int? _userId;

  AuthProvider({required this.api, required this.storage});

  Future<void> tryRestoreSession() async {
    final token = await storage.getToken();
    _role = await storage.getRole();
    _name = await storage.getName();
    _userId = await storage.getUserId();
    _isAuthenticated = token != null;
  }

  Future<void> login(String email, String password) async {
    _busy = true; notifyListeners();
    try {
      final data = await api.login(email, password);
      await storage.saveSession(token: data['token'], role: data['role'], name: data['name'], userId: data['userId']);
      _role = data['role']; _name = data['name']; _userId = data['userId'];
      _isAuthenticated = true;
    } finally {
      _busy = false; notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password, String role) async {
    _busy = true; notifyListeners();
    try {
      final data = await api.register(name, email, password, role);
      await storage.saveSession(token: data['token'], role: data['role'], name: data['name'], userId: data['userId']);
      _role = data['role']; _name = data['name']; _userId = data['userId'];
      _isAuthenticated = true;
    } finally {
      _busy = false; notifyListeners();
    }
  }

  Future<void> logout() async {
    await storage.clear();
    _role = null; _name = null; _userId = null; _isAuthenticated = false;
    notifyListeners();
  }
}
