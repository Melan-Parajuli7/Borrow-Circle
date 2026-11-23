import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FingerprintService {
  static const _enabledKey = 'fingerprint_login_enabled';
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_enabledKey) ?? false;
  }

  Future<bool> canAuthenticate() async {
    final supported =
        await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    if (!supported) return false;
    return _auth.getAvailableBiometrics().then((methods) => methods.isNotEmpty);
  }

  Future<bool> authenticate() async {
    return _auth.authenticate(
      localizedReason: 'Confirm your identity to open BorrowCircle',
      biometricOnly: true,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, enabled);
  }
}
