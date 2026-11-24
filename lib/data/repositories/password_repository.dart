/// Exception thrown by the password repository.
class PasswordRepositoryException implements Exception {
  final String message;

  const PasswordRepositoryException(this.message);

  @override
  String toString() => message;
}

/// Abstract contract for password management data access.
abstract class PasswordRepository {
  /// Changes the password for the demo account.
  ///
  /// Throws [PasswordRepositoryException] on failure.
  Future<bool> changeDemoPassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  });
}