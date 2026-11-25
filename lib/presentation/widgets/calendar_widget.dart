import 'package:add_2_calendar/add_2_calendar.dart' as native_calendar;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/constants/colors.dart';
import '../../data/models/loan_model.dart';
import '../utils/format.dart';
import '../viewmodels/calendar_viewmodel.dart';
import '../viewmodels/loan_viewmodel.dart';
import 'app_widgets.dart';

/// Calendar widget showing upcoming loan start and due dates.
///
/// Events are derived from the user's borrowing and lending loans through
/// [CalendarViewModel]. Tapping the calendar icon on an event opens the
/// device's calendar to add it.
///
/// Pages only use this widget; they do not contain calendar logic themselves.
class CalendarWidget extends StatefulWidget {
  /// Creates a [CalendarWidget] with an optional [key].
  const CalendarWidget({super.key});

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  /// Adds the loan identified by [loanId] to the device's native calendar.
  Future<void> _addToDeviceCalendar(
    int loanId,
    String title,
    String kind,
  ) async {
    final loans = context.read<LoanViewModel>();
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

    // NOTE: add_2_calendar supports Android and iOS only; on other platforms
    // this is a no-op.
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
      final loans = context.read<LoanViewModel>();
      context.read<CalendarViewModel>().load(loans.borrowing, loans.lending);
    });
  }

  @override
  Widget build(BuildContext context) {
    final calendar = context.watch<CalendarViewModel>();
    final selectedEvents = calendar.eventsFor(_selectedDay);

    return Column(
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
            style: Theme.of(context)
                .textTheme
                .titleLarge
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
                    onPressed: () => _addToDeviceCalendar(
                      event.loanId,
                      event.title,
                      event.kind,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
