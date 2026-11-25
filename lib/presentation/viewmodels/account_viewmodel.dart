import '../../data/repositories/account_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for account preferences management.
///
/// Holds notification, theme, handover spot, and contact visibility settings,
/// loading them from and persisting them to [AccountRepository].
class AccountViewModel extends BaseViewModel {
  /// Creates an [AccountViewModel] backed by [repository].
  AccountViewModel(this._repository);

  /// Repository used to read and write account preferences.
  final AccountRepository _repository;

  bool _notificationsEnabled = true;
  /// Whether notifications are enabled.
  bool get notificationsEnabled => _notificationsEnabled;

  String _themeMode = 'system';
  /// Current theme mode: 'light', 'dark', or 'system'.
  String get themeMode => _themeMode;

  String _handoverSpot = '';
  /// Saved default handover location.
  String get handoverSpot => _handoverSpot;

  bool _hideContactInfo = false;
  /// Whether contact info is hidden from non-circle members.
  bool get hideContactInfo => _hideContactInfo;

  /// Loads all preferences from storage.
  Future<void> loadPreferences() async {
    await runWithLoading(() async {
      _notificationsEnabled = await _repository.notificationsEnabled();
      _themeMode = await _repository.themeMode();
      _handoverSpot = await _repository.handoverSpot();
      _hideContactInfo = await _repository.hideContactInfo();
    });
  }

  /// Sets notifications enabled preference.
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    await _repository.setNotificationsEnabled(enabled);
  }

  /// Sets theme mode preference.
  Future<void> setThemeMode(String value) async {
    _themeMode = value;
    notifyListeners();
    await _repository.setThemeMode(value);
  }

  /// Sets handover spot preference.
  Future<void> setHandoverSpot(String value) async {
    _handoverSpot = value.trim();
    notifyListeners();
    await _repository.setHandoverSpot(_handoverSpot);
  }

  /// Sets hide contact info preference.
  Future<void> setHideContactInfo(bool value) async {
    _hideContactInfo = value;
    notifyListeners();
    await _repository.setHideContactInfo(value);
  }
}
