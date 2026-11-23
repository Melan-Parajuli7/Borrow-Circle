class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
  };

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
}
