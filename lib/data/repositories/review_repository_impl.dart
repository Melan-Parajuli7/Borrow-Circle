import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../data/models/paged.dart';
import '../../data/models/review_model.dart';
import 'review_repository.dart';

/// Concrete implementation of [ReviewRepository] backed by the Express API.
class ReviewRepositoryImpl implements ReviewRepository {
  /// API client used to make authenticated HTTP requests.
  final ApiClient _apiClient;

  /// Creates a [ReviewRepositoryImpl] with the given [apiClient].
  ReviewRepositoryImpl(this._apiClient);

  @override
  Future<ReviewModel> createReview({
    required int loanId,
    required int rating,
    String? comment,
  }) async {
    final json = await _apiClient.post(AppConstants.reviewsEndpoint, body: {
      'loan_id': loanId,
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    });
    return ReviewModel.fromJson(json['review']);
  }

  @override
  Future<ReviewsResult> getReceived({int page = 1, int limit = 20}) async {
    final json = await _apiClient.get(AppConstants.receivedReviewsEndpoint,
        query: {'page': page, 'limit': limit});
    return _parse(json);
  }

  @override
  Future<ReviewsResult> getGiven({int page = 1, int limit = 50}) async {
    final json = await _apiClient.get(AppConstants.givenReviewsEndpoint,
        query: {'page': page, 'limit': limit});
    return _parse(json);
  }

  @override
  Future<ReviewsResult> getUserReviews(int userId,
      {int page = 1, int limit = 5}) async {
    final json = await _apiClient.get(
      '${AppConstants.userReviewsEndpoint}/$userId',
      query: {'page': page, 'limit': limit},
    );
    return _parse(json);
  }

  ReviewsResult _parse(Map<String, dynamic> json) {
    final r = (json['result'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return ReviewsResult(
      summary: ReviewSummary.fromJson(r['summary'] as Map<String, dynamic>?),
      reviews: Paged<ReviewModel>.fromJson(r, 'reviews', ReviewModel.fromJson),
    );
  }
}