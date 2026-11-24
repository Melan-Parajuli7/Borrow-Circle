import '../../data/models/loan_model.dart';
import '../../data/repositories/calendar_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for calendar events.
class CalendarViewModel extends BaseViewModel {
  final CalendarRepository _repository;

  CalendarViewModel(this._repository);

  Map<DateTime, List<CalendarEvent>> _events = {};
  Map<DateTime, List<CalendarEvent>> get events => _events;

  /// Builds calendar events from borrowing and lending loans.
  void load(List<LoanModel> borrowing, List<LoanModel> lending) {
    _events = _repository.buildEvents(borrowing, lending);
    notifyListeners();
  }

  /// Gets events for a specific day.
  List<CalendarEvent> eventsFor(DateTime day) {
    return _repository.eventsFor(day, _events);
  }

  @override
  void reset() {
    super.reset();
    _events.clear();
  }
}