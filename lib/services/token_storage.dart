import 'package:shared_preferences/shared_preferences.dart';

/// Saves the login "tokens" on the phone so the user stays logged in
/// after closing the app. (The backend sends them as cookies.)
class TokenStorage {
  TokenStorage._();

  static const _accessKey = 'accessToken';
  static const _refreshKey = 'refreshToken';

  // Kept in memory too, so reading them is instant.
  static String? accessToken;
  static String? refreshToken;

  /// Call once when the app starts.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString(_accessKey);
    refreshToken = prefs.getString(_refreshKey);
  }

  /// Pass null to remove the token.
  static Future<void> setAccess(String? value) async {
    accessToken = value;
    final prefs = await SharedPreferences.getInstance();
    value == null ? await prefs.remove(_accessKey) : await prefs.setString(_accessKey, value);
  }

  static Future<void> setRefresh(String? value) async {
    refreshToken = value;
    final prefs = await SharedPreferences.getInstance();
    value == null ? await prefs.remove(_refreshKey) : await prefs.setString(_refreshKey, value);
  }

  /// Used on logout.
  static Future<void> clear() async {
    await setAccess(null);
    await setRefresh(null);
  }
}
