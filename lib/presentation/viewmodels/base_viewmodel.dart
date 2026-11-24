import 'package:flutter/foundation.dart';

/// Base class for all ViewModels in the application.
///
/// Provides common functionality such as loading state management,
/// error handling, and [ChangeNotifier] integration for reactive UI updates.
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  /// Whether the ViewModel is currently performing an async operation.
  bool get isLoading => _isLoading;

  /// Alias for [isLoading], used by action-oriented screens.
  bool get isBusy => _isLoading;

  /// The last error message, if any.
  String? get error => _error;

  /// Sets the loading state and notifies listeners.
  @protected
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Sets the error message and notifies listeners.
  @protected
  void setError(String? message) {
    _error = message;
    notifyListeners();
  }

  /// Clears the error message and notifies listeners.
  @protected
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Executes an async action with automatic loading and error handling.
  ///
  /// [action] is the async operation to perform.
  /// Returns `true` if the action succeeded, `false` otherwise.
  @protected
  Future<bool> runWithLoading(Future<void> Function() action) async {
    setLoading(true);
    clearError();
    try {
      await action();
      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      return false;
    }
  }

  /// Executes an async action that returns a value, with automatic loading and error handling.
  ///
  /// [action] is the async operation to perform.
  /// Returns the result of the action, or `null` if it failed.
  @protected
  Future<T?> runWithLoadingValue<T>(Future<T> Function() action) async {
    setLoading(true);
    clearError();
    try {
      final result = await action();
      setLoading(false);
      return result;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
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