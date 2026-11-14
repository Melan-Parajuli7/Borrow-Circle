import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:borrowcircle/controller/auth_controller.dart';
import 'package:borrowcircle/controller/group_controller.dart';
import 'package:borrowcircle/controller/item_controller.dart';
import 'package:borrowcircle/controller/loan_controller.dart';
import 'package:borrowcircle/controller/request_controller.dart';
import 'package:borrowcircle/controller/review_controller.dart';
import 'package:borrowcircle/core/static.dart';
import 'package:borrowcircle/pages/welcome.dart';

/// Helpers that touch several controllers at once.
class AppSession {
  AppSession._();

  /// Logs out, clears all cached data and goes back to the Welcome screen.
  static Future<void> logout(BuildContext context) async {
    // read everything BEFORE the await (the context may change afterwards)
    final nav = Navigator.of(context);
    final auth = context.read<AuthController>();
    final items = context.read<ItemController>();
    final requests = context.read<RequestController>();
    final loans = context.read<LoanController>();
    final reviews = context.read<ReviewController>();
    final groups = context.read<GroupController>();

    await auth.logout();
    items.reset();
    requests.reset();
    loans.reset();
    reviews.reset();
    groups.reset();
    AppNav.tabIndex.value = 0;

    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (route) => false,
    );
  }
}
