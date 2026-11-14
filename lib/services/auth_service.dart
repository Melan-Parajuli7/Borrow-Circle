import 'package:borrowcircle/model/user_model.dart';
import 'package:borrowcircle/services/api_service.dart';
import 'package:borrowcircle/services/token_storage.dart';

/// Talks to  /api/users/...  (register, login, logout, me).
/// Services only call the API and return models. They hold no screen logic.
class AuthService {
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final json = await ApiService.post(
      '/users/register',
      body: {'full_name': fullName.trim(), 'email': email.trim(), 'password': password},
      refreshOn401: false,
    );
    return UserModel.fromJson(json['user']);
  }

  Future<UserModel> login({required String email, required String password}) async {
    final json = await ApiService.post(
      '/users/login',
      body: {'email': email.trim(), 'password': password},
      refreshOn401: false,
    );
    return UserModel.fromJson(json['user']);
  }

  Future<UserModel> getMe() async {
    final json = await ApiService.get('/users/me');
    return UserModel.fromJson(json['user']);
  }

  /// PUT /users/me  (name + optional profile picture)
  Future<UserModel> updateProfile({required String fullName, String? avatarPath}) async {
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
