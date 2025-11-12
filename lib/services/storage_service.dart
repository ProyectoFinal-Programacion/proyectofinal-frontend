import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _s = const FlutterSecureStorage();
  static const _kToken = 'auth_token';
  static const _kRole = 'auth_role';
  static const _kName = 'auth_name';
  static const _kUserId = 'auth_user_id';

  Future<void> saveSession({required String token, required String role, required String name, required int userId}) async {
    await _s.write(key: _kToken, value: token);
    await _s.write(key: _kRole, value: role);
    await _s.write(key: _kName, value: name);
    await _s.write(key: _kUserId, value: userId.toString());
  }

  Future<String?> getToken() => _s.read(key: _kToken);
  Future<String?> getRole() => _s.read(key: _kRole);
  Future<String?> getName() => _s.read(key: _kName);
  Future<int?> getUserId() async {
    final v = await _s.read(key: _kUserId);
    if (v == null) return null;
    return int.tryParse(v);
  }

  Future<void> clear() async {
    await _s.deleteAll();
  }
}
