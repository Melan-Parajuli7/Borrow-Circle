import 'package:flutter/material.dart';

import '../../widgets/app_widgets.dart';
import '../../widgets/calendar_widget.dart';

/// Calendar view of upcoming loan start and due dates.
///
/// This page only hosts [CalendarWidget]; all calendar logic lives in the
/// widget and [CalendarViewModel] (provided globally in [main]).
class CalendarScreen extends StatelessWidget {
  /// Creates a [CalendarScreen] with an optional [key].
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Loan calendar'),
            Expanded(
              child: const CalendarWidget(),
            ),
          ],
        ),
      ),
    );
  }
}
