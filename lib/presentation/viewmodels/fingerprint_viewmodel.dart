import '../../data/repositories/fingerprint_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for fingerprint authentication.
class FingerprintViewModel extends BaseViewModel {
  final FingerprintRepository _repository;

  FingerprintViewModel(this._repository);

  bool _enabled = false;
  bool get enabled => _enabled;

  bool _available = false;
  bool get available => _available;

  /// Loads fingerprint settings and availability.
  Future<void> load() async {
    await runWithLoading(() async {
      _enabled = await _repository.isEnabled();
      _available = await _repository.canAuthenticate();
    });
  }

  /// Attempts fingerprint authentication.
  Future<bool> authenticate() async {
    final result = await runWithLoadingValue<bool>(() async {
      return await _repository.authenticate();
    });
    return result ?? false;
  }

  /// Enables or disables fingerprint login.
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