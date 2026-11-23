import 'package:flutter/foundation.dart';

import 'package:borrowcircle/services/password_service.dart';

/// Frontend-only password feature state.
class PasswordController extends ChangeNotifier {
  final PasswordService _service = PasswordService();

  bool isLoading = false;
  String? error;

  Future<bool> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _service.changeDemoPassword(
        email: email,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      isLoading = false;
      notifyListeners();
      return true;
    } on PasswordServiceException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Could not change password. Please try again.';
    }

    isLoading = false;
    notifyListeners();
    return false;
  }
}
