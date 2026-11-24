import 'package:shared_preferences/shared_preferences.dart';

import 'password_repository.dart';

/// Concrete implementation of [PasswordRepository] for demo account management.
class PasswordRepositoryImpl implements PasswordRepository {
  static const String _demoEmail = 'nabin.dhakal@patancollege.edu.np';
  static const String _demoPasswordKey = 'demo_password';
  static const String _initialDemoPassword = 'Nabin@123';

  @override
  Future<bool> changeDemoPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (email.trim().toLowerCase() != _demoEmail) {
      throw PasswordRepositoryException(
        'Password change requires backend support for this account.',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString(_demoPasswordKey) ?? _initialDemoPassword;
    if (currentPassword != savedPassword) {
      throw PasswordRepositoryException('Current password is incorrect.');
    }
    if (newPassword == currentPassword) {
      throw PasswordRepositoryException(
        'New password must be different from the current password.',
      );
    }

    await prefs.setString(_demoPasswordKey, newPassword);
    return true;
  }
}