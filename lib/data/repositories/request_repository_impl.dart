import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../data/models/paged.dart';
import '../../data/models/request_model.dart';
import 'request_repository.dart';

/// Concrete implementation of [RequestRepository] backed by the Express API.
class RequestRepositoryImpl implements RequestRepository {
  /// API client used to make authenticated HTTP requests.
  final ApiClient _apiClient;

  /// Creates a [RequestRepositoryImpl] with the given [apiClient].
  RequestRepositoryImpl(this._apiClient);

  @override
  Future<RequestModel> createRequest({
    required int itemId,
    required String startDate,
    required String endDate,
    String? message,
  }) async {
    final json = await _apiClient.post(AppConstants.requestsEndpoint, body: {
      'item_id': itemId,
      'start_date': startDate,
      'end_date': endDate,
      if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
    });
    return RequestModel.fromJson(json['request']);
  }

  @override
  Future<Paged<RequestModel>> getMy({int page = 1, int limit = 50}) async {
    final json = await _apiClient.get(AppConstants.myRequestsEndpoint,
        query: {'page': page, 'limit': limit});
    return Paged<RequestModel>.fromJson(json, 'requests', RequestModel.fromJson);
  }

  @override
  Future<Paged<RequestModel>> getIncoming({int page = 1, int limit = 50}) async {
    final json = await _apiClient.get(AppConstants.incomingRequestsEndpoint,
        query: {'page': page, 'limit': limit});
    return Paged<RequestModel>.fromJson(json, 'requests', RequestModel.fromJson);
  }

  @override
  Future<RequestModel> getRequest(int id) async {
    final json =
        await _apiClient.get('${AppConstants.requestsEndpoint}/$id');
    return RequestModel.fromJson(json['request']);
  }

  @override
  Future<RequestModel> approve(int id) => _change(id, 'approve');

  @override
  Future<RequestModel> reject(int id) => _change(id, 'reject');

  @override
  Future<RequestModel> cancel(int id) => _change(id, 'cancel');

  Future<RequestModel> _change(int id, String action) async {
    final json = await _apiClient
        .patch('${AppConstants.requestsEndpoint}/$id/$action');
    return RequestModel.fromJson(json['request']);
  }
}