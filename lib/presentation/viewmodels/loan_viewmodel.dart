import '../../data/models/loan_model.dart';
import '../../data/repositories/loan_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for loan management (borrowing, lending, handover, return).
class LoanViewModel extends BaseViewModel {
  final LoanRepository _repository;

  LoanViewModel(this._repository);

  final List<LoanModel> _borrowing = [];
  List<LoanModel> get borrowing => _borrowing;

  final List<LoanModel> _lending = [];
  List<LoanModel> get lending => _lending;

  String? _actionError;
  String? get actionError => _actionError;

  // Derived getters
  List<LoanModel> get activeBorrowing =>
      _borrowing.where((l) => !l.isReturned).toList();

  List<LoanModel> get activeLending =>
      _lending.where((l) => !l.isReturned).toList();

  List<LoanModel> get completedBorrowing =>
      _borrowing.where((l) => l.isReturned).toList();

  List<LoanModel> get completedLending =>
      _lending.where((l) => l.isReturned).toList();

  int get completedCount => completedBorrowing.length + completedLending.length;

  /// Loads all loans (borrowing and lending).
  Future<void> load() async {
    await runWithLoading(() async {
      final results = await Future.wait([
        _repository.getBorrowing(),
        _repository.getLending(),
      ]);
      _borrowing
        ..clear()
        ..addAll(results[0].data);
      _lending
        ..clear()
        ..addAll(results[1].data);
    });
  }

  /// Creates a loan from an approved request.
  Future<LoanModel?> createLoan(int requestId) async {
    return runWithLoadingValue(() async {
      return await _repository.createLoan(requestId);
    });
  }

  /// Fetches a single loan (includes handover code for borrower).
  Future<LoanModel?> fetchLoan(int id) async {
    _actionError = null;
    notifyListeners();
    try {
      return await _repository.getLoan(id);
    } on Exception catch (e) {
      _actionError = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Confirms handover with the borrower's code.
  Future<bool> handover(int id, String code) async {
    return runWithLoading(() async {
      await _repository.handover(id, code);
    });
  }

  /// Confirms return of the borrowed item.
  Future<LoanModel?> returnLoan(int id) async {
    return runWithLoadingValue(() async {
      return await _repository.returnLoan(id);
    });
  }

  @override
  void reset() {
    super.reset();
    _borrowing.clear();
    _lending.clear();
    _actionError = null;
  }
}