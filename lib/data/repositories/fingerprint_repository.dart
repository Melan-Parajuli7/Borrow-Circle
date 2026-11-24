/// Abstract contract for fingerprint authentication data access.
abstract class FingerprintRepository {
  /// Whether fingerprint login is enabled.
  Future<bool> isEnabled();

  /// Whether the device supports fingerprint authentication.
  Future<bool> canAuthenticate();

  /// Attempts fingerprint authentication.
  Future<bool> authenticate();

  /// Sets the fingerprint login enabled preference.
  Future<void> setEnabled(bool enabled);
}