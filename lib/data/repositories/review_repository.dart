import '../../data/models/review_model.dart';

/// Abstract contract for review data access.
abstract class ReviewRepository {
  /// Creates a new review for a completed loan.
  Future<ReviewModel> createReview({
    required int loanId,
    required int rating,
    String? comment,
  });

  /// Fetches reviews received by the current user (with summary).
  Future<ReviewsResult> getReceived({int page = 1, int limit = 20});

  /// Fetches reviews given by the current user.
  Future<ReviewsResult> getGiven({int page = 1, int limit = 50});

  /// Fetches public reviews for a specific user.
  Future<ReviewsResult> getUserReviews(int userId, {int page = 1, int limit = 5});
}