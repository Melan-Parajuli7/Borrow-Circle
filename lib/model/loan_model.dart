class LoanModel {
  final int id;
  final int requestId;
  final int itemId;
  final int borrowerId;
  final int ownerId;
  final String startDate;
  final String endDate;
  final String status; // active | returned | overdue
  /// Derived by the backend: awaiting_handover | on_loan | overdue | returned
  final String stage;
  final DateTime? handedOverAt;
  final DateTime? returnedAt;
  final String itemTitle;
  final String? itemImage;
  final String borrowerName;
  final String? borrowerAvatar;
  final String ownerName;
  final String? ownerAvatar;

  /// 6-digit code. The backend only sends it to the BORROWER while the
  /// stage is "awaiting_handover"; otherwise it is null.
  final String? handoverCode;

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

  bool get awaitingHandover => stage == 'awaiting_handover';
  bool get isOut => stage == 'on_loan' || stage == 'overdue';
  bool get isReturned => stage == 'returned';
  bool get isOverdue => stage == 'overdue';
}
