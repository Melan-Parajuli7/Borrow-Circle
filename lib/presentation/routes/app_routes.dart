import 'package:flutter/material.dart';

import '../screens/add_item_screen.dart';
import '../screens/all_items_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/chat_page.dart';
import '../screens/conversation_list_screen.dart';
import '../screens/groups_screen.dart';
import '../screens/home_screen.dart';
import '../screens/loans_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/requests_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/welcome_screen.dart';

/// Central definition of the app's named routes.
///
/// Use [AppRoutes.splash], [AppRoutes.welcome], [AppRoutes.auth],
/// [AppRoutes.home], [AppRoutes.profile], [AppRoutes.addItem], and the other
/// route constants when navigating, rather than hard-coded strings.
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

  /// All items screen (searchable, filterable item feed).
  static const String allItems = '/all-items';

  /// Conversation list screen (requires authentication).
  static const String conversations = '/conversations';

  /// Individual conversation screen; navigated to with a
  /// [ConversationModel] as route argument.
  static const String chat = '/chat';

  /// Notifications screen.
  static const String notifications = '/notifications';

  /// Loan calendar screen.
  static const String calendar = '/calendar';

  /// My groups screen.
  static const String groups = '/groups';

  /// My loans screen.
  static const String loans = '/loans';

  /// My requests screen.
  static const String requests = '/requests';

  /// Map of route names to their corresponding widget builders, suitable for
  /// passing directly to `MaterialApp.routes`.
  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        welcome: (_) => const WelcomeScreen(),
        auth: (_) => const AuthScreen(),
        home: (_) => const HomeScreen(),
        allItems: (_) => const AllItemsScreen(),
        conversations: (_) => const ConversationListPage(),
        chat: (_) => const ChatPage(),
        notifications: (_) => const NotificationsScreen(),
        calendar: (_) => const CalendarScreen(),
        groups: (_) => const GroupsScreen(),
        loans: (_) => const LoansScreen(),
        requests: (_) => const RequestsScreen(),
        profile: (_) => const ProfileScreen(),
        addItem: (_) => const AddItemScreen(),
      };
}
