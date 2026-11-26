import 'package:shared_preferences/shared_preferences.dart';

import 'account_repository.dart';

/// Concrete implementation of [AccountRepository] using local storage.
class AccountRepositoryImpl implements AccountRepository {
  static const String _notificationsKey = 'account_notifications_enabled';
  static const String _themeKey = 'account_theme_mode';
  static const String _handoverSpotKey = 'account_handover_spot';
  static const String _hideContactKey = 'account_hide_contact';

  @override
  Future<bool> notificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  @override
  Future<String> themeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'light';
  }

  @override
  Future<void> setThemeMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, value);
  }

  @override
  Future<String> handoverSpot() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_handoverSpotKey) ?? '';
  }

  @override
  Future<void> setHandoverSpot(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_handoverSpotKey, value);
  }

  @override
  Future<bool> hideContactInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hideContactKey) ?? false;
  }

  @override
  Future<void> setHideContactInfo(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideContactKey, value);
  }
}