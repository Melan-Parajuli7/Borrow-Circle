import 'package:shared_preferences/shared_preferences.dart';

/// Stores account preferences that do not require a backend service.
class AccountService {
  static const _notificationsKey = 'account_notifications_enabled';

  Future<bool> notificationsEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_notificationsKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_notificationsKey, enabled);
  }
}
