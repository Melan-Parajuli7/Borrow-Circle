import 'package:borrowcircle/model/user_model.dart';
import 'package:borrowcircle/services/api_service.dart';
import 'package:borrowcircle/services/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Talks to  /api/users/...  (register, login, logout, me).
/// Services only call the API and return models. They hold no screen logic.
class AuthService {
  static const _demoEmail = 'nabin.dhakal@patancollege.edu.np';
  static const _demoPassword = 'Nabin@123';
  static const _demoNameKey = 'demo_full_name';
  static const _demoSessionKey = 'demo_session';
  static const _demoPasswordKey = 'demo_password';

  Future<UserModel> _demoLogin(String email, String password) async {
    final preferences = await SharedPreferences.getInstance();
    final savedPassword =
        preferences.getString(_demoPasswordKey) ?? _demoPassword;
    if (email.trim().toLowerCase() != _demoEmail || password != savedPassword) {
      throw ApiException('Invalid email or password', 401);
    }

    await preferences.setBool(_demoSessionKey, true);
    await TokenStorage.setAccess('demo-access-token');
    await TokenStorage.setRefresh('demo-refresh-token');

    final fullName = preferences.getString(_demoNameKey) ?? 'Nabin Dhakal';
    return UserModel(
      id: 1,
      fullName: fullName,
      email: _demoEmail,
      role: 'user',
    );
  }

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final json = await ApiService.post(
        '/users/register',
        body: {
          'full_name': fullName.trim(),
          'email': email.trim(),
          'password': password,
        },
        refreshOn401: false,
      );
      return UserModel.fromJson(json['user']);
    } on ApiException catch (error) {
      if (error.statusCode != null) rethrow;
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_demoSessionKey, true);
      await preferences.setString(_demoNameKey, fullName.trim());
      await TokenStorage.setAccess('demo-access-token');
      await TokenStorage.setRefresh('demo-refresh-token');
      return UserModel(
        id: 1,
        fullName: fullName.trim(),
        email: email.trim(),
        role: 'user',
      );
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().toLowerCase() == _demoEmail) {
      return _demoLogin(email, password);
    }

    try {
      final json = await ApiService.post(
        '/users/login',
        body: {'email': email.trim(), 'password': password},
        refreshOn401: false,
      );
      return UserModel.fromJson(json['user']);
    } on ApiException {
      rethrow;
    }
  }

  Future<UserModel> getMe() async {
    if (TokenStorage.refreshToken == 'demo-refresh-token') {
      final preferences = await SharedPreferences.getInstance();
      final fullName = preferences.getString(_demoNameKey) ?? 'Nabin Dhakal';
      return UserModel(
        id: 1,
        fullName: fullName,
        email: _demoEmail,
        role: 'user',
      );
    }

    final json = await ApiService.get('/users/me');
    return UserModel.fromJson(json['user']);
  }

  /// PUT /users/me  (name + optional profile picture)
  Future<UserModel> updateProfile({
    required String fullName,
    String? avatarPath,
  }) async {
    if (TokenStorage.refreshToken == 'demo-refresh-token') {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_demoNameKey, fullName.trim());
      return UserModel(
        id: 1,
        fullName: fullName.trim(),
        email: _demoEmail,
        role: 'user',
      );
    }

    final json = await ApiService.multipart(
      'PUT',
      '/users/me',
      fields: {'full_name': fullName.trim()},
      fileField: 'avatar',
      filePath: avatarPath,
    );
    return UserModel.fromJson(json['user']);
  }

  Future<void> logout() async {
    try {
      await ApiService.post('/users/logout', refreshOn401: false);
    } catch (_) {
      // even if the server is unreachable we still log out on the phone
    }
    await TokenStorage.clear();
  }

  /// Used when the app opens: are we still logged in?
  Future<UserModel?> restoreSession() async {
    await TokenStorage.load();
    if (TokenStorage.refreshToken == null) return null;
    try {
      return await getMe();
    } on ApiException {
      return null;
    }
  }
}
