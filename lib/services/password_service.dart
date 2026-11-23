import 'package:shared_preferences/shared_preferences.dart';

/// Frontend password feature service.
/// Demo credentials are stored locally until a backend password API exists.
class PasswordService {
  static const _demoEmail = 'nabin.dhakal@patancollege.edu.np';
  static const _demoPasswordKey = 'demo_password';
  static const _initialDemoPassword = 'Nabin@123';

  Future<bool> changeDemoPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (email.trim().toLowerCase() != _demoEmail) {
      throw PasswordServiceException(
        'Password change requires backend support for this account.',
      );
    }

    final preferences = await SharedPreferences.getInstance();
    final savedPassword =
        preferences.getString(_demoPasswordKey) ?? _initialDemoPassword;
    if (currentPassword != savedPassword) {
      throw PasswordServiceException('Current password is incorrect.');
    }
    if (newPassword == currentPassword) {
      throw PasswordServiceException(
        'New password must be different from the current password.',
      );
    }

    await preferences.setString(_demoPasswordKey, newPassword);
    return true;
  }
}

class PasswordServiceException implements Exception {
  final String message;

  const PasswordServiceException(this.message);

  @override
  String toString() => message;
}
