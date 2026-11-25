import 'package:flutter/material.dart';

import '../screens/auth/auth_screen.dart';
import '../screens/chat/chat_page.dart';
import '../screens/chat/conversation_list_page.dart';
import '../screens/home/home_screen.dart';
import '../screens/items/add_item_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/welcome/welcome_screen.dart';

/// Central definition of the app's named routes.
///
/// Use [AppRoutes.splash], [AppRoutes.welcome], [AppRoutes.auth],
/// [AppRoutes.home], [AppRoutes.profile], and [AppRoutes.addItem] when
/// navigating, rather than hard-coded strings.
class AppRoutes {
  AppRoutes._();

  /// Initial splash / session-check screen.
  static const String splash = '/';

  /// Welcome screen shown to unauthenticated users.
  static const String welcome = '/welcome';

  /// Authentication screen (login + registration).
  static const String auth = '/auth';

  /// Home / dashboard screen (requires authentication).
  static const String home = '/home';

  /// Profile screen for viewing and editing account details.
  static const String profile = '/profile';

  /// Screen for listing a new item.
  static const String addItem = '/add-item';

  /// Conversation list screen (requires authentication).
  static const String conversations = '/conversations';

  /// Individual conversation screen; navigated to with a
  /// [ConversationModel] as route argument.
  static const String chat = '/chat';

  /// Map of route names to their corresponding widget builders, suitable for
  /// passing directly to `MaterialApp.routes`.
  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        welcome: (_) => const WelcomeScreen(),
        auth: (_) => const AuthScreen(),
        home: (_) => const HomeScreen(),
        conversations: (_) => const ConversationListPage(),
        chat: (_) => const ChatPage(),
        profile: (_) => const ProfileScreen(),
        addItem: (_) => const AddItemScreen(),
      };
}