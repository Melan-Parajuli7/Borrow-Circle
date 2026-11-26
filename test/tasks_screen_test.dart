import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:borrowcircle/data/repositories/task_repository_impl.dart';
import 'package:borrowcircle/presentation/screens/tasks_screen.dart';
import 'package:borrowcircle/presentation/viewmodels/task_viewmodel.dart';

void main() {
  testWidgets('status and task filters update the visible list', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'account_tasks': [
        jsonEncode({
          'id': 'completed',
          'title': 'Read chapter',
          'isCompleted': true,
          'priority': 'high',
          'category': 'Study',
          'createdAt': '2026-01-02T00:00:00.000',
        }),
        jsonEncode({
          'id': 'pending',
          'title': 'Finish assignment',
          'isCompleted': false,
          'priority': 'medium',
          'category': 'Personal',
          'createdAt': '2026-01-01T00:00:00.000',
        }),
      ],
    });

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TaskViewModel(TaskRepositoryImpl()),
        child: const MaterialApp(home: TasksScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Completed'));
    await tester.pumpAndSettle();
    expect(find.text('Read chapter'), findsOneWidget);
    expect(find.text('Finish assignment'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Pending'));
    await tester.pumpAndSettle();
    expect(find.text('Finish assignment'), findsOneWidget);
    expect(find.text('Read chapter'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Total'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'High'));
    await tester.pumpAndSettle();
    expect(find.text('Read chapter'), findsOneWidget);
    expect(find.text('Finish assignment'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Personal'));
    await tester.pumpAndSettle();
    expect(find.text('No tasks match the selected filters.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.text('Read chapter'), findsOneWidget);
    expect(find.text('Finish assignment'), findsOneWidget);
  });

  testWidgets('task form scrolls on a phone-sized screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TaskViewModel(TaskRepositoryImpl()),
        child: const MaterialApp(home: TasksScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Add Task'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Add Task'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
