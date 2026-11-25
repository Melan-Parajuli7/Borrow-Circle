import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/app_exception.dart';
import '../../data/models/auth_response.dart';
import '../../data/models/user_model.dart';
import 'auth_repository.dart';

/// Concrete implementation of [AuthRepository] backed by the Express API.
///
/// Handles demo mode credentials and persists session tokens via [SharedPreferences].
class AuthRepositoryImpl implements AuthRepository {
  /// Demo account email.
  static const String _demoEmail = 'nabin.dhakal@patancollege.edu.np';

  /// Demo account default password.
  static const String _demoPassword = 'Nabin@123';

  /// SharedPreferences keys for demo mode.
  static const String _demoNameKey = 'demo_full_name';
  static const String _demoSessionKey = 'demo_session';
  static const String _demoPasswordKey = 'demo_password';

  /// API client used to make authenticated HTTP requests.
  final ApiClient _apiClient;

  /// SharedPreferences instance used to persist the auth token and user.
  final SharedPreferences _prefs;

  /// Creates an [AuthRepositoryImpl] with the given [apiClient] and [prefs].
  AuthRepositoryImpl(this._apiClient, this._prefs);

  @override
  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final json = await _apiClient.post(
        AppConstants.registerEndpoint,
        body: {
          'full_name': fullName.trim(),
          'email': email.trim(),
          'password': password,
        },
        refreshOn401: false,
      );
      return AuthResponse.fromJson(json);
    } on AppException catch (error) {
      if (error.statusCode != null) rethrow;
      // Fallback to demo mode if backend unavailable
      await _prefs.setBool(_demoSessionKey, true);
      await _prefs.setString(_demoNameKey, fullName.trim());
      await _prefs.setString(AppConstants.tokenKey, 'demo-access-token');
      await _prefs.setString(AppConstants.refreshTokenKey, 'demo-refresh-token');
      return AuthResponse(
        accessToken: 'demo-access-token',
        refreshToken: 'demo-refresh-token',
        user: UserModel(
          id: 1,
          fullName: fullName.trim(),
          email: email.trim(),
          role: 'user',
        ),
      );
    }
  }

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().toLowerCase() == _demoEmail) {
      return _demoLogin(email, password);
    }

    try {
      final json = await _apiClient.post(
        AppConstants.loginEndpoint,
        body: {'email': email.trim(), 'password': password},
        refreshOn401: false,
      );
      return AuthResponse.fromJson(json);
    } on AppException {
      rethrow;
    }
  }

  Future<AuthResponse> _demoLogin(String email, String password) async {
    final savedPassword = _prefs.getString(_demoPasswordKey) ?? _demoPassword;
    if (email.trim().toLowerCase() != _demoEmail || password != savedPassword) {
      throw BadRequestException('Invalid email or password', 401);
    }

    await _prefs.setBool(_demoSessionKey, true);
    await _prefs.setString(AppConstants.tokenKey, 'demo-access-token');
    await _prefs.setString(AppConstants.refreshTokenKey, 'demo-refresh-token');

    final fullName = _prefs.getString(_demoNameKey) ?? 'Nabin Dhakal';
    return AuthResponse(
      accessToken: 'demo-access-token',
      refreshToken: 'demo-refresh-token',
      user: UserModel(
        id: 1,
        fullName: fullName,
        email: _demoEmail,
        role: 'user',
      ),
    );
  }

  @override
  Future<UserModel> getMe() async {
    if (_prefs.getString(AppConstants.refreshTokenKey) == 'demo-refresh-token') {
      final fullName = _prefs.getString(_demoNameKey) ?? 'Nabin Dhakal';
      return UserModel(
        id: 1,
        fullName: fullName,
        email: _demoEmail,
        role: 'user',
      );
    }

    final json = await _apiClient.get(AppConstants.meEndpoint);
    return UserModel.fromJson(json['user']);
  }

  @override
  UserModel? get currentUser {
    // This would require sync access to SharedPreferences, which isn't possible.
    // The ViewModel should call getMe() or restoreSession() instead.
    return null;
  }

  @override
  String? get accessToken => _prefs.getString(AppConstants.tokenKey);

  @override
  String? get refreshToken => _prefs.getString(AppConstants.refreshTokenKey);

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post(AppConstants.logoutEndpoint, refreshOn401: false);
    } catch (_) {
      // Even if the server is unreachable, we still log out locally.
    }
    await _prefs.remove(AppConstants.tokenKey);
    await _prefs.remove(AppConstants.refreshTokenKey);
  }

  @override
  bool get isLoggedIn => _prefs.getString(AppConstants.refreshTokenKey) != null;

  @override
  Future<UserModel> updateProfile({
    required String fullName,
    String? avatarPath,
  }) async {
    if (_prefs.getString(AppConstants.refreshTokenKey) == 'demo-refresh-token') {
      await _prefs.setString(_demoNameKey, fullName.trim());
      return UserModel(
        id: 1,
        fullName: fullName.trim(),
        email: _demoEmail,
        role: 'user',
      );
    }

    final json = await _apiClient.multipart(
      'PUT',
      AppConstants.meEndpoint,
      fields: {'full_name': fullName.trim()},
      fileField: 'avatar',
      filePath: avatarPath,
    );
    return UserModel.fromJson(json['user']);
  }

  @override
  Future<UserModel?> restoreSession() async {
    if (_prefs.getString(AppConstants.refreshTokenKey) == null) return null;
    try {
      return await getMe();
    } on AppException {
      return null;
    }
  }
}
