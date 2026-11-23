import 'package:flutter/foundation.dart';

import 'package:borrowcircle/services/fingerprint_service.dart';

class FingerprintController extends ChangeNotifier {
  final FingerprintService _service = FingerprintService();

  bool enabled = false;
  bool available = false;
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    enabled = await _service.isEnabled();
    available = await _service.canAuthenticate();
    notifyListeners();
  }

  Future<bool> authenticate() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final ok = await _service.authenticate();
      isLoading = false;
      if (!ok) error = 'Fingerprint authentication was cancelled.';
      notifyListeners();
      return ok;
    } catch (_) {
      isLoading = false;
      error = 'Fingerprint authentication is unavailable.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setEnabled(bool value) async {
    if (value) {
      if (!await authenticate()) return false;
    }
    await _service.setEnabled(value);
    enabled = value;
    notifyListeners();
    return true;
  }
}
