import 'static.dart';

/// Form validators. Each returns an error message, or null when valid.
/// Rules match the backend services, so the user sees errors before the API call.
class Validators {
  Validators._();

  static String? required(String? v, [String label = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  static String? fullName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Full name is required';
    if (v.trim().length > 100) return 'Max 100 characters';
    return null;
  }

  static String? email(String? v) {
    final e = (v ?? '').trim().toLowerCase();
    if (e.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(e)) {
      return 'Enter a valid email';
    }
    final domain = e.split('@').last;
    if (!AppStatic.allowedEmailDomains.contains(domain)) {
      return 'Use your @patancollege.edu.np or @study.beds.ac.uk email';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'At least 8 characters';
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) =>
      (v) => v != original() ? 'Passwords do not match' : null;

  static String? itemTitle(String? v) {
    if (v == null || v.trim().isEmpty) return 'Title is required';
    if (v.trim().length > 150) return 'Max 150 characters';
    return null;
  }

  static String? groupName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Group name is required';
    if (v.trim().length > 100) return 'Max 100 characters';
    return null;
  }

  static String? maxLength(String? v, int max) =>
      (v != null && v.trim().length > max) ? 'Max $max characters' : null;

  static String? handoverCode(String? v) {
    final c = (v ?? '').trim();
    if (c.length != 6 || int.tryParse(c) == null) return 'Enter the 6-digit code';
    return null;
  }
}
