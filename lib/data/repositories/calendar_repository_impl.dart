import '../../data/models/loan_model.dart';
import 'calendar_repository.dart';

/// Concrete implementation of [CalendarRepository].
class CalendarRepositoryImpl implements CalendarRepository {
  @override
  Map<DateTime, List<CalendarEvent>> buildEvents(
    List<LoanModel> borrowing,
    List<LoanModel> lending,
  ) {
    final events = <DateTime, List<CalendarEvent>>{};

    for (final loan in [...borrowing, ...lending]) {
      final start = _parseDay(loan.startDate);
      final end = _parseDay(loan.endDate);
      if (start != null) {
        events.putIfAbsent(start, () => []).add(
              CalendarEvent(
                loanId: loan.id,
                title: '${loan.itemTitle} - starts',
                kind: 'start',
              ),
            );
      }
      if (end != null) {
        events.putIfAbsent(end, () => []).add(
              CalendarEvent(
                loanId: loan.id,
                title: '${loan.itemTitle} - due',
                kind: 'due',
              ),
            );
      }
    }
    return events;
  }

  @override
  List<CalendarEvent> eventsFor(DateTime day, Map<DateTime, List<CalendarEvent>> events) {
    final key = DateTime(day.year, day.month, day.day);
    return events[key] ?? const [];
  }

  DateTime? _parseDay(String s) {
    final d = DateTime.tryParse(s);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }
}