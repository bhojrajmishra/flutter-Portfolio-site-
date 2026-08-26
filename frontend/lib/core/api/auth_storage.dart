import 'package:shared_preferences/shared_preferences.dart';

/// Persists the admin JWT across page reloads (backed by localStorage on web).
class AuthStorage {
  static const _tokenKey = 'admin_jwt_token';

  Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> writeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
