import '../../data/models/loan_model.dart';
import '../../data/repositories/loan_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for loan management (borrowing, lending, handover, return).
///
/// Holds the lists of borrowing and lending loans and delegates data
/// operations to the [LoanRepository].
class LoanViewModel extends BaseViewModel {
  /// Creates a [LoanViewModel] backed by [repository].
  LoanViewModel(this._repository);

  /// Repository used to perform loan operations.
  final LoanRepository _repository;

  final List<LoanModel> _borrowing = [];
  /// Loans where the current user is the borrower.
  List<LoanModel> get borrowing => _borrowing;

  final List<LoanModel> _lending = [];
  /// Loans where the current user is the owner (lender).
  List<LoanModel> get lending => _lending;

  String? _actionError;
  /// Error from the last loan action, if any.
  String? get actionError => _actionError;

  /// Loans that are not yet returned (borrowing).
  List<LoanModel> get activeBorrowing =>
      _borrowing.where((l) => !l.isReturned).toList();

  /// Loans that are not yet returned (lending).
  List<LoanModel> get activeLending =>
      _lending.where((l) => !l.isReturned).toList();

  /// Completed borrowing loans.
  List<LoanModel> get completedBorrowing =>
      _borrowing.where((l) => l.isReturned).toList();

  /// Completed lending loans.
  List<LoanModel> get completedLending =>
      _lending.where((l) => l.isReturned).toList();

  /// Total number of completed loans.
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
  ///
  /// Returns the created [LoanModel] on success, or `null` on failure.
  Future<LoanModel?> createLoan(int requestId) async {
    return runWithLoadingValue(() async {
      return await _repository.createLoan(requestId);
    });
  }

  /// Fetches a single loan (includes handover code for borrower).
  ///
  /// Returns the [LoanModel] on success, or `null` on failure.
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
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> handover(int id, String code) async {
    return runWithLoading(() async {
      await _repository.handover(id, code);
    });
  }

  /// Confirms return of the borrowed item.
  ///
  /// Returns the updated [LoanModel] on success, or `null` on failure.
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
