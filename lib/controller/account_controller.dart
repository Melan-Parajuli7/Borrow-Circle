import 'package:flutter/foundation.dart';

import 'package:borrowcircle/services/account_service.dart';

/// Frontend-only account settings and preferences.
class AccountController extends ChangeNotifier {
  final AccountService _service = AccountService();

  bool notificationsEnabled = true;
  bool isLoading = false;

  Future<void> loadPreferences() async {
    isLoading = true;
    notifyListeners();
    notificationsEnabled = await _service.notificationsEnabled();
    isLoading = false;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    notificationsEnabled = enabled;
    notifyListeners();
    await _service.setNotificationsEnabled(enabled);
  }
}
