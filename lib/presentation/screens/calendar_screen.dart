import 'package:flutter/material.dart';

import '../widgets/app_widgets.dart';
import '../widgets/calendar_widget.dart';

/// Calendar view of upcoming loan start and due dates.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
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
