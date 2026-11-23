import 'package:borrowcircle/core/format.dart';
import 'package:borrowcircle/model/loan_model.dart';

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

class CalendarService {
  Map<DateTime, List<CalendarEvent>> buildEvents(
    List<LoanModel> borrowing,
    List<LoanModel> lending,
  ) {
    final events = <DateTime, List<CalendarEvent>>{};

    for (final loan in [...borrowing, ...lending]) {
      final start = Fmt.parseDay(loan.startDate);
      final end = Fmt.parseDay(loan.endDate);
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
}
