/// Request model representing a borrow request.
///
/// Contains request details, dates, status, and participant information.
class RequestModel {
  /// Unique identifier of the request.
  final int id;

  /// Item ID being requested.
  final int itemId;

  /// Requester's user ID.
  final int requesterId;

  /// Owner's user ID.
  final int ownerId;

  /// Start date of the requested loan (YYYY-MM-DD format).
  final String startDate;

  /// End date of the requested loan (YYYY-MM-DD format).
  final String endDate;

  /// Request status (pending, approved, rejected, cancelled).
  final String status;

  /// Optional message from the requester.
  final String? message;

  /// Title of the requested item.
  final String itemTitle;

  /// Item image URL, if any.
  final String? itemImage;

  /// Requester's display name.
  final String requesterName;

  /// Requester's avatar file name, if any.
  final String? requesterAvatar;

  /// Owner's display name.
  final String ownerName;

  /// Timestamp when the request was created.
  final DateTime? createdAt;

  /// Creates a [RequestModel] with the given properties.
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

  /// Creates a [RequestModel] from a JSON map as returned by the API.
  ///
  /// Expects keys: `id`, `item_id`, `requester_id`, `owner_id`,
  /// `start_date`, `end_date`, `status`, `message`, `item_title`,
  /// `item_image`, `requester_name`, `requester_avatar`, `owner_name`, `created_at`.
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

  /// Converts this [RequestModel] into a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'item_id': itemId,
        'requester_id': requesterId,
        'owner_id': ownerId,
        'start_date': startDate,
        'end_date': endDate,
        'status': status,
        'message': message,
        'item_title': itemTitle,
        'item_image': itemImage,
        'requester_name': requesterName,
        'requester_avatar': requesterAvatar,
        'owner_name': ownerName,
        'created_at': createdAt?.toIso8601String(),
      };

  /// Whether the request is still pending.
  bool get isPending => status == 'pending';

  /// Whether the request has been approved.
  bool get isApproved => status == 'approved';
}