import 'package:flutter/foundation.dart';

import 'package:borrowcircle/model/loan_model.dart';
import 'package:borrowcircle/services/api_service.dart';
import 'package:borrowcircle/services/loan_service.dart';

/// Loans: what I borrow, what I lend, the handover code and the return.
class LoanController extends ChangeNotifier {
  final LoanService _service = LoanService();

  List<LoanModel> borrowing = [];
  List<LoanModel> lending = [];
  bool isLoading = false;
  bool isBusy = false;
  String? error;
  String? actionError;

  // not returned yet
  List<LoanModel> get activeBorrowing => borrowing.where((l) => !l.isReturned).toList();
  List<LoanModel> get activeLending => lending.where((l) => !l.isReturned).toList();

  // finished loans
  List<LoanModel> get completedBorrowing => borrowing.where((l) => l.isReturned).toList();
  List<LoanModel> get completedLending => lending.where((l) => l.isReturned).toList();
  int get completedCount => completedBorrowing.length + completedLending.length;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([_service.getBorrowing(), _service.getLending()]);
      borrowing = results[0].data;
      lending = results[1].data;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not load loans.';
    }
    isLoading = false;
    notifyListeners();
  }

  /// Owner starts the loan. Returns the new loan (or null + [actionError]).
  Future<LoanModel?> createLoan(int requestId) async {
    LoanModel? loan;
    final ok = await _act(() async {
      loan = await _service.createLoan(requestId);
    });
    return ok ? loan : null;
  }

  /// Gets one loan (this is the only call that includes the handover code).
  Future<LoanModel?> fetchLoan(int id) async {
    actionError = null;
    try {
      return await _service.getLoan(id);
    } on ApiException catch (e) {
      actionError = e.message;
    } catch (_) {
      actionError = 'Could not load the loan.';
    }
    return null;
  }

  Future<bool> handover(int id, String code) => _act(() => _service.handover(id, code));

  Future<LoanModel?> returnLoan(int id) async {
    LoanModel? loan;
    final ok = await _act(() async {
      loan = await _service.returnLoan(id);
    });
    return ok ? loan : null;
  }

  Future<bool> _act(Future<void> Function() action) async {
    isBusy = true;
    actionError = null;
    notifyListeners();
    var success = false;
    try {
      await action();
      success = true;
    } on ApiException catch (e) {
      actionError = e.message;
    } catch (_) {
      actionError = 'Something went wrong. Please try again.';
    }
    isBusy = false;
    notifyListeners();
    if (success) await load();
    return success;
  }

  void reset() {
    borrowing = [];
    lending = [];
    error = null;
    notifyListeners();
  }
}
