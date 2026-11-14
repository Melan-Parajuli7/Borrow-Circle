class RequestModel {
  final int id;
  final int itemId;
  final int requesterId;
  final int ownerId;
  final String startDate; // "YYYY-MM-DD" (kept as text, same as the backend)
  final String endDate;
  final String status; // pending | approved | rejected | cancelled
  final String? message;
  final String itemTitle;
  final String? itemImage;
  final String requesterName;
  final String? requesterAvatar;
  final String ownerName;
  final DateTime? createdAt;

  const RequestModel({
    required this.id,
    required this.itemId,
    required this.requesterId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.message,
    this.itemTitle = '',
    this.itemImage,
    this.requesterName = '',
    this.requesterAvatar,
    this.ownerName = '',
    this.createdAt,
  });

  factory RequestModel.fromJson(Map<String, dynamic> j) => RequestModel(
        id: (j['id'] as num).toInt(),
        itemId: (j['item_id'] as num).toInt(),
        requesterId: (j['requester_id'] as num).toInt(),
        ownerId: (j['owner_id'] as num).toInt(),
        startDate: j['start_date'] as String? ?? '',
        endDate: j['end_date'] as String? ?? '',
        status: j['status'] as String? ?? 'pending',
        message: j['message'] as String?,
        itemTitle: j['item_title'] as String? ?? '',
        itemImage: j['item_image'] as String?,
        requesterName: j['requester_name'] as String? ?? '',
        requesterAvatar: j['requester_avatar'] as String?,
        ownerName: j['owner_name'] as String? ?? '',
        createdAt: DateTime.tryParse('${j['created_at']}'),
      );

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
}
