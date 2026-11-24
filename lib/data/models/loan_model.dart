/// Loan model representing a borrowing/lending transaction.
///
/// Contains loan details, participants, dates, status, and handover information.
class LoanModel {
  /// Unique identifier of the loan.
  final int id;

  /// Associated request ID that created this loan.
  final int requestId;

  /// Item ID being borrowed.
  final int itemId;

  /// Borrower's user ID.
  final int borrowerId;

  /// Owner's user ID.
  final int ownerId;

  /// Start date of the loan (YYYY-MM-DD format).
  final String startDate;

  /// End date of the loan (YYYY-MM-DD format).
  final String endDate;

  /// Loan status (active, returned, overdue).
  final String status;

  /// Detailed loan stage (awaiting_handover, on_loan, overdue, returned).
  final String stage;

  /// Timestamp when the item was handed over.
  final DateTime? handedOverAt;

  /// Timestamp when the item was returned.
  final DateTime? returnedAt;

  /// Title of the borrowed item.
  final String itemTitle;

  /// Item image URL, if any.
  final String? itemImage;

  /// Borrower's display name.
  final String borrowerName;

  /// Borrower's avatar file name, if any.
  final String? borrowerAvatar;

  /// Owner's display name.
  final String ownerName;

  /// Owner's avatar file name, if any.
  final String? ownerAvatar;

  /// 6-digit handover code (only sent to borrower during awaiting_handover stage).
  final String? handoverCode;

  /// Creates a [LoanModel] with the given properties.
  const LoanModel({
    required this.id,
    required this.requestId,
    required this.itemId,
    required this.borrowerId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.stage,
    this.handedOverAt,
    this.returnedAt,
    this.itemTitle = '',
    this.itemImage,
    this.borrowerName = '',
    this.borrowerAvatar,
    this.ownerName = '',
    this.ownerAvatar,
    this.handoverCode,
  });

  /// Creates a [LoanModel] from a JSON map as returned by the API.
  ///
  /// Expects keys: `id`, `request_id`, `item_id`, `borrower_id`, `owner_id`,
  /// `start_date`, `end_date`, `status`, `stage`, `handed_over_at`, `returned_at`,
  /// `item_title`, `item_image`, `borrower_name`, `borrower_avatar`,
  /// `owner_name`, `owner_avatar`, `handover_code`.
  factory LoanModel.fromJson(Map<String, dynamic> j) => LoanModel(
        id: (j['id'] as num).toInt(),
        requestId: (j['request_id'] as num).toInt(),
        itemId: (j['item_id'] as num).toInt(),
        borrowerId: (j['borrower_id'] as num).toInt(),
        ownerId: (j['owner_id'] as num).toInt(),
        startDate: j['start_date'] as String? ?? '',
        endDate: j['end_date'] as String? ?? '',
        status: j['status'] as String? ?? 'active',
        stage: j['stage'] as String? ?? 'awaiting_handover',
        handedOverAt: DateTime.tryParse('${j['handed_over_at']}'),
        returnedAt: DateTime.tryParse('${j['returned_at']}'),
        itemTitle: j['item_title'] as String? ?? '',
        itemImage: j['item_image'] as String?,
        borrowerName: j['borrower_name'] as String? ?? '',
        borrowerAvatar: j['borrower_avatar'] as String?,
        ownerName: j['owner_name'] as String? ?? '',
        ownerAvatar: j['owner_avatar'] as String?,
        handoverCode: j['handover_code'] as String?,
      );

  /// Converts this [LoanModel] into a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'request_id': requestId,
        'item_id': itemId,
        'borrower_id': borrowerId,
        'owner_id': ownerId,
        'start_date': startDate,
        'end_date': endDate,
        'status': status,
        'stage': stage,
        'handed_over_at': handedOverAt?.toIso8601String(),
        'returned_at': returnedAt?.toIso8601String(),
        'item_title': itemTitle,
        'item_image': itemImage,
        'borrower_name': borrowerName,
        'borrower_avatar': borrowerAvatar,
        'owner_name': ownerName,
        'owner_avatar': ownerAvatar,
        'handover_code': handoverCode,
      };

  /// Whether the loan is awaiting handover.
  bool get awaitingHandover => stage == 'awaiting_handover';

  /// Whether the loan is currently active (on loan or overdue).
  bool get isOut => stage == 'on_loan' || stage == 'overdue';

  /// Whether the loan has been returned.
  bool get isReturned => stage == 'returned';

  /// Whether the loan is overdue.
  bool get isOverdue => stage == 'overdue';
}