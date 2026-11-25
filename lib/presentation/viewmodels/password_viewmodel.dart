import '../../data/repositories/password_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for password management.
///
/// Delegates password change operations to [PasswordRepository].
class PasswordViewModel extends BaseViewModel {
  /// Creates a [PasswordViewModel] backed by [repository].
  PasswordViewModel(this._repository);

  /// Repository used to change the demo account password.
  final PasswordRepository _repository;

  /// Changes the password for the demo account.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    return runWithLoading(() async {
      await _repository.changeDemoPassword(
        email: email,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    });
  }
}
