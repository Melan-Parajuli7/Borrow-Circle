// Basic smoke test for the BorrowCircle app.
//
// Verifies that the app boots and renders the splash screen without
// throwing. The splash screen performs the session check and then
// redirects to Home or Welcome.
//
// The real provider graph is created in `main()`; here we provide the
// ViewModels the root widget depends on so the widget can build in isolation.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:borrowcircle/app.dart';
import 'package:borrowcircle/data/repositories/account_repository_impl.dart';
import 'package:borrowcircle/data/repositories/auth_repository_impl.dart';
import 'package:borrowcircle/data/repositories/calendar_repository_impl.dart';
import 'package:borrowcircle/data/repositories/fingerprint_repository_impl.dart';
import 'package:borrowcircle/data/repositories/group_repository_impl.dart';
import 'package:borrowcircle/data/repositories/item_repository_impl.dart';
import 'package:borrowcircle/data/repositories/loan_repository_impl.dart';
import 'package:borrowcircle/data/repositories/notification_repository_impl.dart';
import 'package:borrowcircle/data/repositories/password_repository_impl.dart';
import 'package:borrowcircle/data/repositories/request_repository_impl.dart';
import 'package:borrowcircle/data/repositories/review_repository_impl.dart';
import 'package:borrowcircle/core/network/api_client.dart';
import 'package:borrowcircle/presentation/viewmodels/account_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/auth_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/calendar_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/fingerprint_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/group_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/item_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/loan_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/notification_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/password_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/request_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/review_viewmodel.dart';

void main() {
  testWidgets('App boots and shows the splash screen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final apiClient = ApiClient(http.Client());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthViewModel(AuthRepositoryImpl(apiClient))),
          ChangeNotifierProvider(create: (_) => AccountViewModel(AccountRepositoryImpl())),
          ChangeNotifierProvider(create: (_) => FingerprintViewModel(FingerprintRepositoryImpl())),
          ChangeNotifierProvider(create: (_) => CalendarViewModel(CalendarRepositoryImpl())),
          ChangeNotifierProvider(create: (_) => NotificationViewModel(NotificationRepositoryImpl())),
          ChangeNotifierProvider(create: (_) => PasswordViewModel(PasswordRepositoryImpl())),
          ChangeNotifierProvider(create: (_) => ItemViewModel(ItemRepositoryImpl(apiClient))),
          ChangeNotifierProvider(create: (_) => RequestViewModel(RequestRepositoryImpl(apiClient))),
          ChangeNotifierProvider(create: (_) => LoanViewModel(LoanRepositoryImpl(apiClient))),
          ChangeNotifierProvider(create: (_) => ReviewViewModel(ReviewRepositoryImpl(apiClient))),
          ChangeNotifierProvider(create: (_) => GroupViewModel(GroupRepositoryImpl(apiClient))),
        ],
        child: const BorrowCircleApp(),
      ),
    );

    await tester.pump();

    // The splash screen renders a loading indicator while restoring the session.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let the splash settle: it waits 1.5s, then navigates to Welcome
    // (no stored session) so no timer is left pending.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
  });
}