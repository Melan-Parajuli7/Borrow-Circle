import '../../data/repositories/fingerprint_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for fingerprint authentication.
///
/// Holds fingerprint enabled state and device availability, delegating
/// biometric operations to [FingerprintRepository].
class FingerprintViewModel extends BaseViewModel {
  /// Creates a [FingerprintViewModel] backed by [repository].
  FingerprintViewModel(this._repository);

  /// Repository used to perform fingerprint authentication.
  final FingerprintRepository _repository;

  bool _enabled = false;
  /// Whether fingerprint login is currently enabled.
  bool get enabled => _enabled;

  bool _available = false;
  /// Whether the device supports fingerprint authentication.
  bool get available => _available;

  /// Loads fingerprint settings and availability.
  Future<void> load() async {
    await runWithLoading(() async {
      _enabled = await _repository.isEnabled();
      _available = await _repository.canAuthenticate();
    });
  }

  /// Attempts fingerprint authentication.
  ///
  /// Returns `true` if authentication succeeded.
  Future<bool> authenticate() async {
    final result = await runWithLoadingValue<bool>(() async {
      return await _repository.authenticate();
    });
    return result ?? false;
  }

  /// Enables or disables fingerprint login.
  ///
  /// When enabling, requires successful authentication first. Returns `true`
  /// on success.
  Future<bool> setEnabled(bool value) async {
    if (value) {
      if (!await authenticate()) return false;
    }
    await _repository.setEnabled(value);
    _enabled = value;
    notifyListeners();
    return true;
  }
}
