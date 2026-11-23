import 'package:flutter/foundation.dart';

import 'package:borrowcircle/model/loan_model.dart';
import 'package:borrowcircle/services/calendar_service.dart';

class CalendarController extends ChangeNotifier {
  final CalendarService _service = CalendarService();

  Map<DateTime, List<CalendarEvent>> events = {};

  void load(List<LoanModel> borrowing, List<LoanModel> lending) {
    events = _service.buildEvents(borrowing, lending);
    notifyListeners();
  }

  List<CalendarEvent> eventsFor(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return events[key] ?? const [];
  }
}
