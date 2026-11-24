import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_static.dart';
import '../screens/welcome/welcome_screen.dart';
import 'account_viewmodel.dart';
import 'auth_viewmodel.dart';
import 'calendar_viewmodel.dart';
import 'group_viewmodel.dart';
import 'item_viewmodel.dart';
import 'loan_viewmodel.dart';
import 'notification_viewmodel.dart';
import 'request_viewmodel.dart';
import 'review_viewmodel.dart';

/// Helpers that coordinate several ViewModels at once.
///
/// Acts as the MVVM replacement for the old MVC `AppSession` controller helper.
class AppSession {
  AppSession._();

  /// Logs out, clears all cached ViewModel state and returns to the Welcome
  /// screen.
  static Future<void> logout(BuildContext context) async {
    // read everything BEFORE the await (the context may change afterwards)
    final nav = Navigator.of(context);
    final auth = context.read<AuthViewModel>();
    final account = context.read<AccountViewModel>();
    final items = context.read<ItemViewModel>();
    final requests = context.read<RequestViewModel>();
    final loans = context.read<LoanViewModel>();
    final reviews = context.read<ReviewViewModel>();
    final groups = context.read<GroupViewModel>();
    final notifications = context.read<NotificationViewModel>();
    final calendar = context.read<CalendarViewModel>();

    await auth.logout();
    account.reset();
    items.reset();
    requests.reset();
    loans.reset();
    reviews.reset();
    groups.reset();
    notifications.reset();
    calendar.reset();
    AppNav.tabIndex.value = 0;

    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }
}