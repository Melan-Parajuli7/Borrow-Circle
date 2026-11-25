import 'package:flutter/foundation.dart';

/// Base class for all ViewModels in the MVVM architecture.
///
/// Provides:
/// - [isLoading] / [isBusy] flag for UI spinners
/// - [error] string for error messages
/// - [setBusy] / [setError] / [clearError] helpers
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  /// Whether the ViewModel is currently performing an async operation.
  bool get isLoading => _isLoading;

  /// Alias for [isLoading], used by action-oriented screens.
  bool get isBusy => _isLoading;

  /// The last error message, if any.
  String? get error => _error;

  /// Sets loading state and notifies listeners. Also clears any existing error.
  void setBusy(bool value) {
    _isLoading = value;
    _error = null;
    notifyListeners();
  }

  /// Sets an error message and stops loading.
  void setError(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }

  /// Clears any existing error without changing loading state.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Executes an async action with automatic loading and error handling.
  ///
  /// [action] is the async operation to perform.
  /// Returns `true` if the action succeeded, `false` otherwise.
  Future<bool> runWithLoading(Future<void> Function() action) async {
    setBusy(true);
    clearError();
    try {
      await action();
      setBusy(false);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  /// Executes an async action that returns a value, with automatic loading and
  /// error handling.
  ///
  /// [action] is the async operation to perform.
  /// Returns the result of the action, or `null` if it failed.
  Future<T?> runWithLoadingValue<T>(Future<T> Function() action) async {
    setBusy(true);
    clearError();
    try {
      final result = await action();
      setBusy(false);
      return result;
    } catch (e) {
      setError(e.toString());
      return null;
    }
  }

  /// Resets the ViewModel to its initial state.
  /// Override in subclasses to clear domain-specific state.
  void reset() {
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
