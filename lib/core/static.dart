import 'package:flutter/foundation.dart';

/// App-wide constants. Change [_port] to the PORT in the backend's .env file.
class AppStatic {
  AppStatic._();

  static const int _port = 5000;

  /// Override when running:  flutter run --dart-define=API_HOST=http://192.168.1.5:5000
  static const String _override = String.fromEnvironment('API_HOST');

  /// Host without "/api". Android emulator reaches your PC at 10.0.2.2.
  static String get host {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$_port';
    }
    return 'http://localhost:$_port';
  }

  static String get apiUrl => '$host/api';

  /// Backend stores image paths like "/uploads/items_images/x.jpg".
  static String? imageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '$host$path';
  }

  /// Avatars are stored as a bare file name (see users.avatar).
  static String? avatarUrl(String? file) {
    if (file == null || file.isEmpty) return null;
    if (file.startsWith('http')) return file;
    return '$host/uploads/profile_pics/$file';
  }

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
}

/// Lets any page switch the bottom tab (0 Home, 1 Requests, 2 Loans, 3 Profile).
class AppNav {
  AppNav._();
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);
}
