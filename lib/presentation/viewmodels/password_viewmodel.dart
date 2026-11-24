import '../../data/repositories/password_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for password management.
class PasswordViewModel extends BaseViewModel {
  final PasswordRepository _repository;

  PasswordViewModel(this._repository);

  /// Changes the password for the demo account.
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