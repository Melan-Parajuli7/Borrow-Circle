import 'package:flutter/foundation.dart';

import 'package:borrowcircle/services/account_service.dart';

/// Frontend-only account settings and preferences.
class AccountController extends ChangeNotifier {
  final AccountService _service = AccountService();

  bool notificationsEnabled = true;
  String themeMode = 'system';
  String handoverSpot = '';
  bool hideContactInfo = false;
  bool isLoading = false;

  Future<void> loadPreferences() async {
    isLoading = true;
    notifyListeners();
    notificationsEnabled = await _service.notificationsEnabled();
    themeMode = await _service.themeMode();
    handoverSpot = await _service.handoverSpot();
    hideContactInfo = await _service.hideContactInfo();
    isLoading = false;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    notificationsEnabled = enabled;
    notifyListeners();
    await _service.setNotificationsEnabled(enabled);
  }

  Future<void> setThemeMode(String value) async {
    themeMode = value;
    notifyListeners();
    await _service.setThemeMode(value);
  }

  Future<void> setHandoverSpot(String value) async {
    handoverSpot = value.trim();
    notifyListeners();
    await _service.setHandoverSpot(handoverSpot);
  }

  Future<void> setHideContactInfo(bool value) async {
    hideContactInfo = value;
    notifyListeners();
    await _service.setHideContactInfo(value);
  }
}
