import '../../data/models/request_model.dart';
import '../../data/repositories/request_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for borrow request management (sent, received, approve, reject, cancel).
class RequestViewModel extends BaseViewModel {
  final RequestRepository _repository;

  RequestViewModel(this._repository);

  final List<RequestModel> _sent = [];
  List<RequestModel> get sent => _sent;

  final List<RequestModel> _received = [];
  List<RequestModel> get received => _received;

  String? _actionError;
  String? get actionError => _actionError;

  int get pendingReceived => _received.where((r) => r.isPending).length;

  /// Loads all requests (sent and received).
  Future<void> load() async {
    await runWithLoading(() async {
      final results = await Future.wait([
        _repository.getMy(),
        _repository.getIncoming(),
      ]);
      _sent
        ..clear()
        ..addAll(results[0].data);
      _received
        ..clear()
        ..addAll(results[1].data);
    });
  }

  /// Creates a new borrow request.
  Future<RequestModel?> createRequest({
    required int itemId,
    required String startDate,
    required String endDate,
    String? message,
  }) async {
    return runWithLoadingValue(() async {
      return await _repository.createRequest(
        itemId: itemId,
        startDate: startDate,
        endDate: endDate,
        message: message,
      );
    });
  }

  /// Approves a request.
  Future<bool> approve(int id) async {
    return runWithLoading(() async {
      await _repository.approve(id);
    });
  }

  /// Rejects a request.
  Future<bool> reject(int id) async {
    return runWithLoading(() async {
      await _repository.reject(id);
    });
  }

  /// Cancels a request.
  Future<bool> cancel(int id) async {
    return runWithLoading(() async {
      await _repository.cancel(id);
    });
  }

  @override
  void reset() {
    super.reset();
    _sent.clear();
    _received.clear();
    _actionError = null;
  }
}