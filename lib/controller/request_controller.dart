import 'package:flutter/foundation.dart';

import 'package:borrowcircle/model/request_model.dart';
import 'package:borrowcircle/services/api_service.dart';
import 'package:borrowcircle/services/request_service.dart';

/// Borrow requests: the ones I sent and the ones I received.
class RequestController extends ChangeNotifier {
  final RequestService _service = RequestService();

  List<RequestModel> sent = [];
  List<RequestModel> received = [];
  bool isLoading = false;
  bool isBusy = false; // true while approve / reject / cancel / create is running
  String? error;
  String? actionError;

  int get pendingReceived => received.where((r) => r.isPending).length;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([_service.getMy(), _service.getIncoming()]);
      sent = results[0].data;
      received = results[1].data;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not load requests.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<RequestModel?> createRequest({
    required int itemId,
    required String startDate,
    required String endDate,
    String? message,
  }) async {
    RequestModel? created;
    final ok = await _act(() async {
      created = await _service.createRequest(
        itemId: itemId,
        startDate: startDate,
        endDate: endDate,
        message: message,
      );
    });
    return ok ? created : null;
  }

  Future<bool> approve(int id) => _act(() => _service.approve(id));
  Future<bool> reject(int id) => _act(() => _service.reject(id));
  Future<bool> cancel(int id) => _act(() => _service.cancel(id));

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
    sent = [];
    received = [];
    error = null;
    notifyListeners();
  }
}
