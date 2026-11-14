import 'package:borrowcircle/model/paged.dart';
import 'package:borrowcircle/model/request_model.dart';
import 'package:borrowcircle/services/api_service.dart';

/// Talks to  /api/requests/...  (borrow requests)
class RequestService {
  /// POST /requests   dates are "YYYY-MM-DD"
  Future<RequestModel> createRequest({
    required int itemId,
    required String startDate,
    required String endDate,
    String? message,
  }) async {
    final json = await ApiService.post('/requests', body: {
      'item_id': itemId,
      'start_date': startDate,
      'end_date': endDate,
      if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
    });
    return RequestModel.fromJson(json['request']);
  }

  /// Requests I SENT
  Future<Paged<RequestModel>> getMy({int page = 1, int limit = 50}) async {
    final json = await ApiService.get('/requests/my', query: {'page': page, 'limit': limit});
    return Paged<RequestModel>.fromJson(json, 'requests', RequestModel.fromJson);
  }

  /// Requests for MY items (received)
  Future<Paged<RequestModel>> getIncoming({int page = 1, int limit = 50}) async {
    final json = await ApiService.get('/requests/incoming', query: {'page': page, 'limit': limit});
    return Paged<RequestModel>.fromJson(json, 'requests', RequestModel.fromJson);
  }

  Future<RequestModel> getRequest(int id) async {
    final json = await ApiService.get('/requests/$id');
    return RequestModel.fromJson(json['request']);
  }

  Future<RequestModel> approve(int id) => _change(id, 'approve');
  Future<RequestModel> reject(int id) => _change(id, 'reject');
  Future<RequestModel> cancel(int id) => _change(id, 'cancel');

  Future<RequestModel> _change(int id, String action) async {
    final json = await ApiService.patch('/requests/$id/$action');
    return RequestModel.fromJson(json['request']);
  }
}
