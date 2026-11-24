import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/paged.dart';
import 'loan_repository.dart';

/// Concrete implementation of [LoanRepository] backed by the Express API.
class LoanRepositoryImpl implements LoanRepository {
  /// API client used to make authenticated HTTP requests.
  final ApiClient _apiClient;

  /// Creates a [LoanRepositoryImpl] with the given [apiClient].
  LoanRepositoryImpl(this._apiClient);

  @override
  Future<LoanModel> createLoan(int requestId) async {
    final json = await _apiClient
        .post(AppConstants.loansEndpoint, body: {'request_id': requestId});
    return LoanModel.fromJson(json['loan']);
  }

  @override
  Future<Paged<LoanModel>> getBorrowing({int page = 1, int limit = 50}) async {
    final json = await _apiClient.get(AppConstants.borrowingEndpoint,
        query: {'page': page, 'limit': limit});
    return Paged<LoanModel>.fromJson(json, 'loans', LoanModel.fromJson);
  }

  @override
  Future<Paged<LoanModel>> getLending({int page = 1, int limit = 50}) async {
    final json = await _apiClient.get(AppConstants.lendingEndpoint,
        query: {'page': page, 'limit': limit});
    return Paged<LoanModel>.fromJson(json, 'loans', LoanModel.fromJson);
  }

  @override
  Future<LoanModel> getLoan(int id) async {
    final json = await _apiClient.get('${AppConstants.loansEndpoint}/$id');
    return LoanModel.fromJson(json['loan']);
  }

  @override
  Future<LoanModel> handover(int id, String code) async {
    final json = await _apiClient.patch(
      '${AppConstants.loansEndpoint}/$id/handover',
      body: {'code': code.trim()},
    );
    return LoanModel.fromJson(json['loan']);
  }

  @override
  Future<LoanModel> returnLoan(int id) async {
    final json = await _apiClient
        .patch('${AppConstants.loansEndpoint}/$id/return');
    return LoanModel.fromJson(json['loan']);
  }
}