import 'package:flutter/foundation.dart';

import 'package:borrowcircle/model/user_model.dart';
import 'package:borrowcircle/services/api_service.dart';
import 'package:borrowcircle/services/auth_service.dart';

/// The "brain" for login / register / profile. Pages never call the API directly:
///   Page  ->  Controller  ->  Service  ->  Backend
/// When something changes we call notifyListeners() and the screen rebuilds.
class AuthController extends ChangeNotifier {
  final AuthService _service = AuthService();

  UserModel? user;
  bool isLoading = false;
  String? error;

  bool get isLoggedIn => user != null;

  /// Called by the splash screen.
  Future<void> tryAutoLogin() async {
    user = await _service.restoreSession();
    notifyListeners();
  }

  Future<bool> login(String email, String password) => _run(() async {
        user = await _service.login(email: email, password: password);
      });

  Future<bool> register(String fullName, String email, String password) => _run(() async {
        user = await _service.register(fullName: fullName, email: email, password: password);
      });

  Future<bool> updateProfile(String fullName, {String? avatarPath}) => _run(() async {
        user = await _service.updateProfile(fullName: fullName, avatarPath: avatarPath);
      });

  Future<void> logout() async {
    await _service.logout();
    user = null;
    notifyListeners();
  }

  // Runs an action with loading + error handling, so every method doesn't repeat it.
  Future<bool> _run(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();

    var success = false;
    try {
      await action();
      success = true;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
    }

    isLoading = false;
    notifyListeners();
    return success;
  }
}
