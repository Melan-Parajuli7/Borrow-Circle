import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:borrowcircle/core/network/api_client.dart';
import 'package:borrowcircle/data/repositories/account_repository_impl.dart';
import 'package:borrowcircle/data/repositories/auth_repository_impl.dart';
import 'package:borrowcircle/data/repositories/fingerprint_repository_impl.dart';
import 'package:borrowcircle/presentation/screens/account_screen.dart';
import 'package:borrowcircle/presentation/viewmodels/account_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/auth_viewmodel.dart';
import 'package:borrowcircle/presentation/viewmodels/fingerprint_viewmodel.dart';

void main() {
  testWidgets('handover spot editor stays compact and saves the location', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final account = AccountViewModel(AccountRepositoryImpl());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthViewModel(
              AuthRepositoryImpl(ApiClient(http.Client(), prefs), prefs),
            ),
          ),
          ChangeNotifierProvider.value(value: account),
          ChangeNotifierProvider(
            create: (_) => FingerprintViewModel(FingerprintRepositoryImpl()),
          ),
        ],
        child: const MaterialApp(home: AccountSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final handoverSpotRow = find.text('Default handover spot');
    await tester.scrollUntilVisible(
      handoverSpotRow,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(handoverSpotRow);
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    final dialogSurface = find.descendant(
      of: dialog,
      matching: find.byWidgetPredicate(
        (widget) => widget is Material && widget.type == MaterialType.card,
      ),
    );
    expect(tester.getSize(dialogSurface).height, lessThan(500));

    await tester.enterText(
      find.byType(TextField),
      '  Main Library, North Desk  ',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(account.handoverSpot, 'Main Library, North Desk');
    expect(tester.takeException(), isNull);
  });
}
