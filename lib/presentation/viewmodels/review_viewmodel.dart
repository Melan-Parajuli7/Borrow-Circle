import '../../data/models/paged.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for review management.
///
/// Holds received reviews and the rating summary for the current user.
/// Delegates data operations to the [ReviewRepository].
class ReviewViewModel extends BaseViewModel {
  /// Creates a [ReviewViewModel] backed by [repository].
  ReviewViewModel(this._repository);

  /// Repository used to perform review operations.
  final ReviewRepository _repository;

  ReviewSummary _summary = const ReviewSummary();
  /// Rating summary for reviews received by the current user.
  ReviewSummary get summary => _summary;

  final List<ReviewModel> _received = [];
  /// Reviews received by the current user.
  List<ReviewModel> get received => _received;

  final Set<int> _reviewedLoanIds = {};
  /// IDs of loans the user has already reviewed.
  Set<int> get reviewedLoanIds => _reviewedLoanIds;

  String? _actionError;
  /// Error from the last review action, if any.
  String? get actionError => _actionError;

  /// Loads reviews received by the current user.
  Future<void> loadReceived() async {
    try {
      final result = await _repository.getReceived();
      _summary = result.summary;
      _received
        ..clear()
        ..addAll(result.reviews.data);
      notifyListeners();
    } catch (_) {
      // Silently ignore errors for loading received reviews
    }
  }

  /// Loads reviews given by the current user.
  Future<void> loadGiven() async {
    try {
      final result = await _repository.getGiven();
      _reviewedLoanIds.clear();
      _reviewedLoanIds.addAll(result.reviews.data.map((e) => e.loanId));
      notifyListeners();
    } catch (_) {
      // Silently ignore errors for loading given reviews
    }
  }

  /// Creates a new review for a completed loan.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> createReview({
    required int loanId,
    required int rating,
    String? comment,
  }) async {
    return runWithLoading(() async {
      await _repository.createReview(loanId: loanId, rating: rating, comment: comment);
      _reviewedLoanIds.add(loanId);
    });
  }

  /// Fetches public reviews for a specific user.
  ///
  /// Returns a [ReviewsResult] containing the rating summary and a page of
  /// reviews. Used to show an owner's rating on the item details screen.
  Future<ReviewsResult> getUserReviews(int userId, {int page = 1, int limit = 5}) async {
    try {
      return await _repository.getUserReviews(userId, page: page, limit: limit);
    } catch (e) {
      setError(e.toString());
      return const ReviewsResult(
        summary: ReviewSummary(),
        reviews: Paged(
          data: [],
          total: 0,
          page: 1,
          limit: 5,
          hasMore: false,
        ),
      );
    }
  }

  @override
  void reset() {
    super.reset();
    _summary = const ReviewSummary();
    _received.clear();
    _reviewedLoanIds.clear();
    _actionError = null;
  }
}
