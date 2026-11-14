import 'package:borrowcircle/model/paged.dart';
import 'package:borrowcircle/model/review_model.dart';
import 'package:borrowcircle/services/api_service.dart';

/// Reviews + the rating summary that comes with them.
class ReviewsResult {
  final ReviewSummary summary;
  final Paged<ReviewModel> reviews;
  const ReviewsResult({required this.summary, required this.reviews});
}

/// Talks to  /api/reviews/...
class ReviewService {
  /// POST /reviews  (rating 1-5, only after the item was returned)
  Future<ReviewModel> createReview({required int loanId, required int rating, String? comment}) async {
    final json = await ApiService.post('/reviews', body: {
      'loan_id': loanId,
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    });
    return ReviewModel.fromJson(json['review']);
  }

  /// Reviews other people wrote about me (+ my average)
  Future<ReviewsResult> getReceived({int page = 1, int limit = 20}) async {
    final json = await ApiService.get('/reviews/received', query: {'page': page, 'limit': limit});
    return _parse(json);
  }

  /// Reviews I wrote
  Future<ReviewsResult> getGiven({int page = 1, int limit = 50}) async {
    final json = await ApiService.get('/reviews/given', query: {'page': page, 'limit': limit});
    return _parse(json);
  }

  /// Public rating of another user (shown on Item details)
  Future<ReviewsResult> getUserReviews(int userId, {int page = 1, int limit = 5}) async {
    final json = await ApiService.get('/reviews/user/$userId', query: {'page': page, 'limit': limit});
    return _parse(json);
  }

  // The backend wraps these three answers inside "result".
  ReviewsResult _parse(Map<String, dynamic> json) {
    final r = (json['result'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return ReviewsResult(
      summary: ReviewSummary.fromJson(r['summary'] as Map<String, dynamic>?),
      reviews: Paged<ReviewModel>.fromJson(r, 'reviews', ReviewModel.fromJson),
    );
  }
}
