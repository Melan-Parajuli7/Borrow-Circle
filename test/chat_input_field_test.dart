import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:borrowcircle/presentation/widgets/chat_input_field.dart';

void main() {
  testWidgets('keeps message text when the send request fails', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatInputField(onSend: (_) async => false)),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Pickup at 3?');
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Pickup at 3?',
    );
  });

  testWidgets('clears message text after a successful send', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatInputField(onSend: (_) async => true)),
      ),
    );

    await tester.enterText(find.byType(TextField), 'On my way');
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });
}
