/// Notification model representing a user notification.
class NotificationModel {
  /// Unique identifier of the notification.
  final String id;

  /// Title of the notification.
  final String title;

  /// Message content of the notification.
  final String message;

  /// Whether the notification has been read.
  final bool isRead;

  /// Timestamp when the notification was created.
  final DateTime createdAt;

  /// Creates a [NotificationModel] with the given properties.
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  /// Creates a [NotificationModel] from a JSON map.
  ///
  /// Expects keys: `id`, `title`, `message`, `is_read`, `created_at`.
  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        isRead: json['is_read'] == true,
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  /// Converts this [NotificationModel] into a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  /// Creates a copy of this notification with updated fields.
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) =>
      NotificationModel(
        id: id ?? this.id,
        title: title ?? this.title,
        message: message ?? this.message,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
      );
}