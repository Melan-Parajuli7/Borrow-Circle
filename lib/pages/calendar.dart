import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as native_calendar;

import 'package:borrowcircle/controller/calendar_controller.dart';
import 'package:borrowcircle/controller/loan_controller.dart';
import 'package:borrowcircle/core/colors.dart';
import 'package:borrowcircle/core/format.dart';
import 'package:borrowcircle/core/widgets.dart';
import 'package:borrowcircle/model/loan_model.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Future<void> _addToGoogleCalendar(
    int loanId,
    String title,
    String kind,
  ) async {
    final loans = context.read<LoanController>();
    LoanModel? loan;
    for (final item in [...loans.borrowing, ...loans.lending]) {
      if (item.id == loanId) {
        loan = item;
        break;
      }
    }
    if (loan == null) return;

    final date = kind == 'due'
        ? Fmt.parseDay(loan.endDate)
        : Fmt.parseDay(loan.startDate);
    if (date == null) return;

    await native_calendar.Add2Calendar.addEvent2Cal(
      native_calendar.Event(
        title: 'BorrowCircle: $title',
        description: 'BorrowCircle loan date',
        location: 'BorrowCircle',
        startDate: date,
        endDate: date.add(const Duration(hours: 1)),
        allDay: true,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loans = context.read<LoanController>();
      context.read<CalendarController>().load(loans.borrowing, loans.lending);
    });
  }

  @override
  Widget build(BuildContext context) {
    final calendar = context.watch<CalendarController>();
    final selectedEvents = calendar.eventsFor(_selectedDay);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Loan calendar'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2025, 1, 1),
                    lastDay: DateTime.utc(2035, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: calendar.eventsFor,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppColors.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Events',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (selectedEvents.isEmpty)
                    const EmptyState(
                      icon: Icons.event_available,
                      title: 'No loan events',
                      message: 'No lending or borrowing dates are scheduled.',
                    )
                  else
                    for (final event in selectedEvents)
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: event.kind == 'due'
                              ? AppColors.errorLight
                              : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              event.kind == 'due'
                                  ? Icons.event_busy
                                  : Icons.event_available,
                              color: event.kind == 'due'
                                  ? AppColors.error
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Add to Google Calendar',
                              icon: const Icon(
                                Icons.event_available,
                                color: AppColors.primary,
                              ),
                              onPressed: () => _addToGoogleCalendar(
                                event.loanId,
                                event.title,
                                event.kind,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
