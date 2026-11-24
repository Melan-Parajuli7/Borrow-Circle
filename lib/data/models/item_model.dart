/// Item model representing a borrowable item in the BorrowCircle application.
///
/// Contains item details, ownership information, and availability status.
class ItemModel {
  /// Unique identifier of the item.
  final int id;

  /// Title of the item.
  final String title;

  /// Optional description of the item.
  final String? description;

  /// Image URL path (relative to backend host), if any.
  final String? imageUrl;

  /// Category of the item (e.g., 'Study essentials', 'Electronics').
  final String? category;

  /// Condition of the item (new, like_new, good, fair, poor).
  final String condition;

  /// Owner's user ID.
  final int ownerId;

  /// Whether this is a group item.
  final bool isGroupItem;

  /// Group name (if [isGroupItem] is true).
  final String? groupName;

  /// Whether the item is currently available for borrowing.
  final bool isAvailable;

  /// Owner's display name.
  final String ownerName;

  /// Owner's avatar file name, if any.
  final String? ownerAvatar;

  /// Timestamp when the item was created.
  final DateTime? createdAt;

  /// Creates an [ItemModel] with the given properties.
  const ItemModel({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.category,
    this.condition = 'good',
    required this.ownerId,
    this.isGroupItem = false,
    this.groupName,
    this.isAvailable = true,
    this.ownerName = '',
    this.ownerAvatar,
    this.createdAt,
  });

  /// Creates an [ItemModel] from a JSON map as returned by the API.
  ///
  /// Expects keys: `id`, `title`, `description`, `image_url`, `category`,
  /// `condition`, `owner_id`, `is_group_item`, `group_name`, `is_available`,
  /// `owner_name`, `owner_avatar`, `created_at`.
  factory ItemModel.fromJson(Map<String, dynamic> j) => ItemModel(
        id: (j['id'] as num).toInt(),
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        imageUrl: j['image_url'] as String?,
        category: j['category'] as String?,
        condition: j['condition'] as String? ?? 'good',
        ownerId: (j['owner_id'] as num).toInt(),
        isGroupItem: j['is_group_item'] as bool? ?? false,
        groupName: j['group_name'] as String?,
        isAvailable: j['is_available'] as bool? ?? true,
        ownerName: j['owner_name'] as String? ?? '',
        ownerAvatar: j['owner_avatar'] as String?,
        createdAt: DateTime.tryParse('${j['created_at']}'),
      );

  /// Converts this [ItemModel] into a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'category': category,
        'condition': condition,
        'owner_id': ownerId,
        'is_group_item': isGroupItem,
        'group_name': groupName,
        'is_available': isAvailable,
        'owner_name': ownerName,
        'owner_avatar': ownerAvatar,
        'created_at': createdAt?.toIso8601String(),
      };
}