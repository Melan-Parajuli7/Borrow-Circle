import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for authentication (login, register, profile).
class AuthViewModel extends BaseViewModel {
  final AuthRepository _repository;

  AuthViewModel(this._repository);

  UserModel? _user;
  UserModel? get user => _user;

  bool get isLoggedIn => _user != null;

  /// Attempts to restore a session from stored tokens.
  Future<void> tryAutoLogin() async {
    final user = await _repository.restoreSession();
    _user = user;
    notifyListeners();
  }

  /// Logs in a user with email and password.
  Future<bool> login(String email, String password) async {
    return runWithLoading(() async {
      final response = await _repository.login(email: email, password: password);
      _user = response.user;
    });
  }

  /// Registers a new user.
  Future<bool> register(String fullName, String email, String password) async {
    return runWithLoading(() async {
      final response = await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      _user = response.user;
    });
  }

  /// Updates the user's profile.
  Future<bool> updateProfile(String fullName, {String? avatarPath}) async {
    return runWithLoading(() async {
      _user = await _repository.updateProfile(fullName: fullName, avatarPath: avatarPath);
    });
  }

  /// Logs out the current user.
  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    notifyListeners();
  }

  @override
  void reset() {
    super.reset();
    _user = null;
  }
}