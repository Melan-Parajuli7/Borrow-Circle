import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/app_exception.dart';
import '../../data/datasources/local/token_storage.dart';
import '../../data/models/auth_response.dart';
import '../../data/models/user_model.dart';
import 'auth_repository.dart';

/// Concrete implementation of [AuthRepository] backed by the Express API.
///
/// Handles demo mode credentials and persists session tokens via [TokenStorage].
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

  /// Creates an [AuthRepositoryImpl] with the given [apiClient].
  AuthRepositoryImpl(this._apiClient);

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_demoSessionKey, true);
      await prefs.setString(_demoNameKey, fullName.trim());
      await TokenStorage.setAccess('demo-access-token');
      await TokenStorage.setRefresh('demo-refresh-token');
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
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString(_demoPasswordKey) ?? _demoPassword;
    if (email.trim().toLowerCase() != _demoEmail || password != savedPassword) {
      throw BadRequestException('Invalid email or password', 401);
    }

    await prefs.setBool(_demoSessionKey, true);
    await TokenStorage.setAccess('demo-access-token');
    await TokenStorage.setRefresh('demo-refresh-token');

    final fullName = prefs.getString(_demoNameKey) ?? 'Nabin Dhakal';
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
    if (TokenStorage.refreshToken == 'demo-refresh-token') {
      final prefs = await SharedPreferences.getInstance();
      final fullName = prefs.getString(_demoNameKey) ?? 'Nabin Dhakal';
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
  String? get accessToken => TokenStorage.accessToken;

  @override
  String? get refreshToken => TokenStorage.refreshToken;

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post(AppConstants.logoutEndpoint, refreshOn401: false);
    } catch (_) {
      // Even if the server is unreachable, we still log out locally.
    }
    await TokenStorage.clear();
  }

  @override
  bool get isLoggedIn => TokenStorage.refreshToken != null;

  @override
  Future<UserModel> updateProfile({
    required String fullName,
    String? avatarPath,
  }) async {
    if (TokenStorage.refreshToken == 'demo-refresh-token') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_demoNameKey, fullName.trim());
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
    await TokenStorage.load();
    if (TokenStorage.refreshToken == null) return null;
    try {
      return await getMe();
    } on AppException {
      return null;
    }
  }
}