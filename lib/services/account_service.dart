import 'package:shared_preferences/shared_preferences.dart';

/// Stores account preferences that do not require a backend service.
class AccountService {
  static const _notificationsKey = 'account_notifications_enabled';
  static const _themeKey = 'account_theme_mode';
  static const _handoverSpotKey = 'account_handover_spot';
  static const _hideContactKey = 'account_hide_contact';

  Future<bool> notificationsEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_notificationsKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_notificationsKey, enabled);
  }

  Future<String> themeMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_themeKey) ?? 'system';
  }

  Future<void> setThemeMode(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeKey, value);
  }

  Future<String> handoverSpot() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_handoverSpotKey) ?? '';
  }

  Future<void> setHandoverSpot(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_handoverSpotKey, value);
  }

  Future<bool> hideContactInfo() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_hideContactKey) ?? false;
  }

  Future<void> setHideContactInfo(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_hideContactKey, value);
  }
}
