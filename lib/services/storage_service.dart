import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _key = 'bank_auth_token';

  static Future<void> removeLegacyToken() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('auth_token');
  }

  static Future<void> saveToken(String token) =>
      _storage.write(key: _key, value: token);
  static Future<String?> getToken() => _storage.read(key: _key);
  static Future<void> clearToken() => _storage.delete(key: _key);
}