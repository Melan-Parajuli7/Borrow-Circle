import 'package:borrowcircle/model/loan_model.dart';
import 'package:borrowcircle/model/paged.dart';
import 'package:borrowcircle/services/api_service.dart';

/// Talks to  /api/loans/...
class LoanService {
  /// Owner starts a loan from an APPROVED request. The borrower then gets a 6-digit code.
  Future<LoanModel> createLoan(int requestId) async {
    final json = await ApiService.post('/loans', body: {'request_id': requestId});
    return LoanModel.fromJson(json['loan']);
  }

  /// Loans where I am the borrower
  Future<Paged<LoanModel>> getBorrowing({int page = 1, int limit = 50}) async {
    final json = await ApiService.get('/loans/borrowing', query: {'page': page, 'limit': limit});
    return Paged<LoanModel>.fromJson(json, 'loans', LoanModel.fromJson);
  }

  /// Loans where I am the owner (I lent my item)
  Future<Paged<LoanModel>> getLending({int page = 1, int limit = 50}) async {
    final json = await ApiService.get('/loans/lending', query: {'page': page, 'limit': limit});
    return Paged<LoanModel>.fromJson(json, 'loans', LoanModel.fromJson);
  }

  /// One loan. Only here does the borrower receive handover_code.
  Future<LoanModel> getLoan(int id) async {
    final json = await ApiService.get('/loans/$id');
    return LoanModel.fromJson(json['loan']);
  }

  /// Owner enters the borrower's code to confirm the handover.
  Future<LoanModel> handover(int id, String code) async {
    final json = await ApiService.patch('/loans/$id/handover', body: {'code': code.trim()});
    return LoanModel.fromJson(json['loan']);
  }

  /// Owner confirms the item came back.
  Future<LoanModel> returnLoan(int id) async {
    final json = await ApiService.patch('/loans/$id/return');
    return LoanModel.fromJson(json['loan']);
  }
}
