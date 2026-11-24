import 'package:shared_preferences/shared_preferences.dart';

/// Local data source for storing authentication tokens.
///
/// Persists access and refresh tokens to [SharedPreferences] so the session
/// survives app restarts. Also keeps an in-memory cache for instant reads.
class TokenStorage {
  TokenStorage._();

  static const String _accessKey = 'accessToken';
  static const String _refreshKey = 'refreshToken';

  /// In-memory cache of the access token.
  static String? accessToken;

  /// In-memory cache of the refresh token.
  static String? refreshToken;

  /// Loads tokens from persistent storage into memory.
  ///
  /// Call once during app initialization.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString(_accessKey);
    refreshToken = prefs.getString(_refreshKey);
  }

  /// Sets the access token in memory and persistent storage.
  ///
  /// Pass `null` to remove the token.
  static Future<void> setAccess(String? value) async {
    accessToken = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_accessKey);
    } else {
      await prefs.setString(_accessKey, value);
    }
  }

  /// Sets the refresh token in memory and persistent storage.
  ///
  /// Pass `null` to remove the token.
  static Future<void> setRefresh(String? value) async {
    refreshToken = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_refreshKey);
    } else {
      await prefs.setString(_refreshKey, value);
    }
  }

  /// Clears both tokens from memory and persistent storage.
  ///
  /// Used during logout.
  static Future<void> clear() async {
    await setAccess(null);
    await setRefresh(null);
  }
}