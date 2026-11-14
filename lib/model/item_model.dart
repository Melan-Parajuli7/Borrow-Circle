class ItemModel {
  final int id;
  final String title;
  final String? description;
  final String? imageUrl; // "/uploads/items_images/x.jpg", see AppStatic.imageUrl()
  final String? category;
  final String condition; // new | like_new | good | fair | poor
  final int ownerId;
  final bool isGroupItem;
  final String? groupName;
  final bool isAvailable;
  final String ownerName;
  final String? ownerAvatar;
  final DateTime? createdAt;

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
}
