/// Abstract contract for account preferences data access.
abstract class AccountRepository {
  /// Whether notifications are enabled.
  Future<bool> notificationsEnabled();

  /// Sets the notifications enabled preference.
  Future<void> setNotificationsEnabled(bool enabled);

  /// Gets the current theme mode ('light', 'dark', 'system').
  Future<String> themeMode();

  /// Sets the theme mode preference.
  Future<void> setThemeMode(String value);

  /// Gets the saved handover spot.
  Future<String> handoverSpot();

  /// Sets the handover spot preference.
  Future<void> setHandoverSpot(String value);

  /// Whether to hide contact info.
  Future<bool> hideContactInfo();

  /// Sets the hide contact info preference.
  Future<void> setHideContactInfo(bool value);
}