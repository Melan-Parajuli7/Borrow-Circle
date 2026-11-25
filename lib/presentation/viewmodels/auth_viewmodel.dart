import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for authentication screens (login / register / profile).
///
/// Exposes authentication state to the UI and delegates business logic to the
/// [AuthRepository]. Notifies listeners whenever loading or error state
/// changes so the UI can rebuild.
class AuthViewModel extends BaseViewModel {
  /// Creates an [AuthViewModel] backed by [repository].
  AuthViewModel(this._repository);

  /// Repository used to perform registration, login, and session management.
  final AuthRepository _repository;

  UserModel? _user;
  UserModel? get user => _user;

  /// Whether a valid session is currently established.
  bool get isLoggedIn => _user != null;

  /// Attempts to restore a session from stored tokens.
  ///
  /// Sets the cached [user] from local storage without making a network call
  /// unless the token needs validation.
  Future<void> tryAutoLogin() async {
    final user = await _repository.restoreSession();
    _user = user;
    notifyListeners();
  }

  /// Logs in a user with [email] and [password].
  ///
  /// Sets [isLoading] to true during the request and captures any error via
  /// [setError]. Returns `true` on success, `false` on failure.
  Future<bool> login(String email, String password) async {
    return runWithLoading(() async {
      final response = await _repository.login(email: email, password: password);
      _user = response.user;
    });
  }

  /// Registers a new user with [fullName], [email], and [password].
  ///
  /// Sets [isLoading] to true during the request and captures any error via
  /// [setError]. Returns `true` on success, `false` on failure.
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

  /// Updates the user's profile with [fullName] and optional [avatarPath].
  ///
  /// Only non-null parameters are sent to the server (partial update).
  /// Returns `true` on success, `false` on failure.
  Future<bool> updateProfile(String fullName, {String? avatarPath}) async {
    return runWithLoading(() async {
      _user = await _repository.updateProfile(fullName: fullName, avatarPath: avatarPath);
    });
  }

  /// Logs out the current user: clears the cached user and notifies listeners.
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
