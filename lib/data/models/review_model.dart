import 'paged.dart';

/// Review model representing a user review after a completed loan.
class ReviewModel {
  /// Unique identifier of the review.
  final int id;

  /// Associated loan ID.
  final int loanId;

  /// Reviewer's user ID.
  final int reviewerId;

  /// Reviewee's user ID.
  final int revieweeId;

  /// Rating value (1-5).
  final int rating;

  /// Optional comment text.
  final String? comment;

  /// Reviewer's display name.
  final String reviewerName;

  /// Reviewer's avatar file name, if any.
  final String? reviewerAvatar;

  /// Reviewee's display name.
  final String revieweeName;

  /// Title of the item involved in the loan.
  final String itemTitle;

  /// Timestamp when the review was created.
  final DateTime? createdAt;

  /// Creates a [ReviewModel] with the given properties.
  const ReviewModel({
    required this.id,
    required this.loanId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    this.reviewerName = '',
    this.reviewerAvatar,
    this.revieweeName = '',
    this.itemTitle = '',
    this.createdAt,
  });

  /// Creates a [ReviewModel] from a JSON map as returned by the API.
  ///
  /// Expects keys: `id`, `loan_id`, `reviewer_id`, `reviewee_id`, `rating`,
  /// `comment`, `reviewer_name`, `reviewer_avatar`, `reviewee_name`, `item_title`, `created_at`.
  factory ReviewModel.fromJson(Map<String, dynamic> j) => ReviewModel(
        id: (j['id'] as num).toInt(),
        loanId: (j['loan_id'] as num).toInt(),
        reviewerId: (j['reviewer_id'] as num).toInt(),
        revieweeId: (j['reviewee_id'] as num).toInt(),
        rating: (j['rating'] as num).toInt(),
        comment: j['comment'] as String?,
        reviewerName: j['reviewer_name'] as String? ?? '',
        reviewerAvatar: j['reviewer_avatar'] as String?,
        revieweeName: j['reviewee_name'] as String? ?? '',
        itemTitle: j['item_title'] as String? ?? '',
        createdAt: DateTime.tryParse('${j['created_at']}'),
      );

  /// Converts this [ReviewModel] into a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'loan_id': loanId,
        'reviewer_id': reviewerId,
        'reviewee_id': revieweeId,
        'rating': rating,
        'comment': comment,
        'reviewer_name': reviewerName,
        'reviewer_avatar': reviewerAvatar,
        'reviewee_name': revieweeName,
        'item_title': itemTitle,
        'created_at': createdAt?.toIso8601String(),
      };
}

/// Summary of reviews for a user (total count and average rating).
class ReviewSummary {
  /// Total number of reviews.
  final int total;

  /// Average rating (0-5).
  final double average;

  /// Creates a [ReviewSummary] with the given [total] and [average].
  const ReviewSummary({this.total = 0, this.average = 0});

  /// Creates a [ReviewSummary] from a JSON map.
  ///
  /// Expects keys: `total`, `average`.
  factory ReviewSummary.fromJson(Map<String, dynamic>? j) => ReviewSummary(
        total: (j?['total'] as num?)?.toInt() ?? 0,
        average: (j?['average'] as num?)?.toDouble() ?? 0,
      );
}

/// Result container for paginated reviews with summary.
class ReviewsResult {
  /// Rating summary for the reviews.
  final ReviewSummary summary;

  /// Paginated list of reviews.
  final Paged<ReviewModel> reviews;

  /// Creates a [ReviewsResult] with the given [summary] and [reviews].
  const ReviewsResult({required this.summary, required this.reviews});
}