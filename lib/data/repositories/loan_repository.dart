import '../../data/models/loan_model.dart';
import '../../data/models/paged.dart';

/// Abstract contract for loan data access.
abstract class LoanRepository {
  /// Creates a loan from an approved request.
  Future<LoanModel> createLoan(int requestId);

  /// Fetches loans where the current user is the borrower.
  Future<Paged<LoanModel>> getBorrowing({int page = 1, int limit = 50});

  /// Fetches loans where the current user is the owner (lender).
  Future<Paged<LoanModel>> getLending({int page = 1, int limit = 50});

  /// Fetches a single loan by ID (includes handover code for borrower).
  Future<LoanModel> getLoan(int id);

  /// Confirms handover with the borrower's code.
  Future<LoanModel> handover(int id, String code);

  /// Confirms return of the borrowed item.
  Future<LoanModel> returnLoan(int id);
}