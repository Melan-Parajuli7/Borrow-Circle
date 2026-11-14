class ReviewModel {
  final int id;
  final int loanId;
  final int reviewerId;
  final int revieweeId;
  final int rating; // 1..5
  final String? comment;
  final String reviewerName;
  final String? reviewerAvatar;
  final String revieweeName;
  final String itemTitle;
  final DateTime? createdAt;

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
}

/// { total, average } returned with received / user reviews.
class ReviewSummary {
  final int total;
  final double average;

  const ReviewSummary({this.total = 0, this.average = 0});

  factory ReviewSummary.fromJson(Map<String, dynamic>? j) => ReviewSummary(
        total: (j?['total'] as num?)?.toInt() ?? 0,
        average: (j?['average'] as num?)?.toDouble() ?? 0,
      );
}
