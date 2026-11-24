import '../../data/models/user_model.dart';
import '../../data/models/auth_response.dart';

/// Abstract contract for authentication data access.
///
/// The ViewModel depends on this interface rather than a concrete implementation,
/// making it easy to swap the backing store (e.g., for unit tests with a mock repository)
/// without changing the presentation layer.
abstract class AuthRepository {
  /// Registers a new user with the given [fullName], [email], and [password].
  ///
  /// Returns an [AuthResponse] containing the session tokens and user profile.
  /// Throws an [ApiException] if registration fails (e.g., duplicate email).
  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
  });

  /// Logs in a user with the given [email] and [password].
  ///
  /// Returns an [AuthResponse] containing the session tokens and user profile.
  /// Throws an [ApiException] if credentials are invalid.
  Future<AuthResponse> login({
    required String email,
    required String password,
  });

  /// Fetches the logged-in user's profile from the server.
  ///
  /// Requires a valid session. Throws an [ApiException] if the request fails.
  Future<UserModel> getMe();

  /// Returns the currently cached [UserModel], if one exists locally.
  ///
  /// Does not make a network request; reads from memory or SharedPreferences.
  UserModel? get currentUser;

  /// Returns the stored access token, if any.
  String? get accessToken;

  /// Returns the stored refresh token, if any.
  String? get refreshToken;

  /// Clears all stored session data (tokens and user profile).
  ///
  /// Called when the user logs out.
  Future<void> logout();

  /// Returns `true` if a valid session token is currently stored.
  bool get isLoggedIn;

  /// Updates the logged-in user's profile.
  ///
  /// Only non-null parameters are sent to the server (partial update).
  /// Returns the updated [UserModel] on success.
  /// Throws an [ApiException] if the update fails.
  Future<UserModel> updateProfile({
    required String fullName,
    String? avatarPath,
  });

  /// Attempts to restore a session from stored tokens.
  ///
  /// Returns the [UserModel] if successful, `null` otherwise.
  Future<UserModel?> restoreSession();
}