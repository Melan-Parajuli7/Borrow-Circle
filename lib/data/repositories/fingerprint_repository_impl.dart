import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fingerprint_repository.dart';

/// Concrete implementation of [FingerprintRepository] using local_auth.
class FingerprintRepositoryImpl implements FingerprintRepository {
  static const String _enabledKey = 'fingerprint_login_enabled';
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  @override
  Future<bool> canAuthenticate() async {
    final supported = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    if (!supported) return false;
    final methods = await _auth.getAvailableBiometrics();
    return methods.isNotEmpty;
  }

  @override
  Future<bool> authenticate() async {
    return _auth.authenticate(
      localizedReason: 'Confirm your identity to open BorrowCircle',
      biometricOnly: true,
    );
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }
}