import 'package:flutter/foundation.dart';

import 'app_constants.dart';

/// App-wide helpers that mirror backend rules and build asset URLs.
///
/// Network location comes from [AppConstants] (the single source of truth);
/// this class only adds the host-relative URL builders and static lookup
/// tables the UI needs.
class AppStatic {
  AppStatic._();

  /// Backend stores image paths like "/uploads/items_images/x.jpg".
  static String? imageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${AppConstants.baseUrl}$path';
  }

  /// Avatars are stored as a bare file name (see users.avatar).
  static String? avatarUrl(String? file) {
    if (file == null || file.isEmpty) return null;
    if (file.startsWith('http')) return file;
    return '${AppConstants.baseUrl}/uploads/profile_pics/$file';
  }

  /// Host without "/api", useful for building absolute links.
  static String get host => AppConstants.baseUrl;

  /// Full API root (`host` + [AppConstants.apiPrefix]).
  static String get apiUrl =>
      '${AppConstants.baseUrl}${AppConstants.apiPrefix}';

  // ---- values that mirror backend rules ----
  static const allowedEmailDomains = ['patancollege.edu.np', 'study.beds.ac.uk'];
  static const maxBorrowDays = 30;

  static const conditions = ['new', 'like_new', 'good', 'fair', 'poor'];
  static const categories = [
    'Study essentials',
    'Textbooks',
    'Project tools',
    'Lab equipment',
    'Electronics',
    'Sports equipment',
    'Other',
  ];

  /// "like_new" -> "Like new"
  static String pretty(String s) {
    if (s.isEmpty) return s;
    final t = s.replaceAll('_', ' ');
    return t[0].toUpperCase() + t.substring(1);
  }

  /// Shows the university name under the user's name.
  static String universityOf(String email) {
    final domain = email.split('@').last.toLowerCase();
    if (domain == 'patancollege.edu.np') return 'Patan College';
    if (domain == 'study.beds.ac.uk') return 'University of Bedfordshire';
    return 'Campus';
  }

  /// Whether the app is running on a physical Android device (kept for parity
  /// with the previous implementation; the URL itself lives in
  /// [AppConstants]).
  static bool get isAndroidDevice =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

/// Lets any page switch the bottom tab (0 Home, 1 Requests, 2 Loans, 3 Profile).
class AppNav {
  AppNav._();
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);
}