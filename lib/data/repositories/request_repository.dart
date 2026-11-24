import '../../data/models/request_model.dart';
import '../../data/models/paged.dart';

/// Abstract contract for request data access.
abstract class RequestRepository {
  /// Creates a new borrow request.
  Future<RequestModel> createRequest({
    required int itemId,
    required String startDate,
    required String endDate,
    String? message,
  });

  /// Fetches requests sent by the current user.
  Future<Paged<RequestModel>> getMy({int page = 1, int limit = 50});

  /// Fetches requests received for the current user's items.
  Future<Paged<RequestModel>> getIncoming({int page = 1, int limit = 50});

  /// Fetches a single request by ID.
  Future<RequestModel> getRequest(int id);

  /// Approves a request.
  Future<RequestModel> approve(int id);

  /// Rejects a request.
  Future<RequestModel> reject(int id);

  /// Cancels a request.
  Future<RequestModel> cancel(int id);
}