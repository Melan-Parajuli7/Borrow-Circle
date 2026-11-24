import '../../data/models/loan_model.dart';

/// Calendar event model.
class CalendarEvent {
  final int loanId;
  final String title;
  final String kind;

  const CalendarEvent({
    required this.loanId,
    required this.title,
    required this.kind,
  });
}

/// Abstract contract for calendar data access.
abstract class CalendarRepository {
  /// Builds calendar events from borrowing and lending loans.
  Map<DateTime, List<CalendarEvent>> buildEvents(
    List<LoanModel> borrowing,
    List<LoanModel> lending,
  );

  /// Gets events for a specific day.
  List<CalendarEvent> eventsFor(DateTime day, Map<DateTime, List<CalendarEvent>> events);
}