import 'package:flutter/foundation.dart';

import 'package:borrowcircle/model/review_model.dart';
import 'package:borrowcircle/services/api_service.dart';
import 'package:borrowcircle/services/review_service.dart';

/// Reviews I received (profile rating) and reviews I already gave.
class ReviewController extends ChangeNotifier {
  final ReviewService _service = ReviewService();

  ReviewSummary summary = const ReviewSummary();
  List<ReviewModel> received = [];

  /// Loan ids I already reviewed (so the "Leave a review" button can hide).
  Set<int> reviewedLoanIds = {};

  bool isBusy = false;
  String? actionError;

  Future<void> loadReceived() async {
    try {
      final r = await _service.getReceived();
      summary = r.summary;
      received = r.reviews.data;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadGiven() async {
    try {
      final r = await _service.getGiven();
      reviewedLoanIds = r.reviews.data.map((e) => e.loanId).toSet();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createReview({required int loanId, required int rating, String? comment}) async {
    isBusy = true;
    actionError = null;
    notifyListeners();
    var success = false;
    try {
      await _service.createReview(loanId: loanId, rating: rating, comment: comment);
      reviewedLoanIds = {...reviewedLoanIds, loanId};
      success = true;
    } on ApiException catch (e) {
      actionError = e.message;
    } catch (_) {
      actionError = 'Something went wrong. Please try again.';
    }
    isBusy = false;
    notifyListeners();
    return success;
  }

  void reset() {
    summary = const ReviewSummary();
    received = [];
    reviewedLoanIds = {};
    notifyListeners();
  }
}
