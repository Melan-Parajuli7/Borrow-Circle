/// A message returned by the BorrowCircle chat API.
class MessageModel {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.senderName = '',
    this.senderAvatar,
    this.isRead = false,
  });

  final int id;
  final int conversationId;
  final int senderId;
  final String text;
  final DateTime sentAt;
  final String senderName;
  final String? senderAvatar;
  final bool isRead;

  bool isSentBy(String userId) => senderId.toString() == userId;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    dynamic field(String camelCase, String snakeCase) =>
        json[camelCase] ?? json[snakeCase];
    int number(dynamic value) =>
        value is num ? value.toInt() : int.parse(value.toString());

    return MessageModel(
      id: number(json['id']),
      conversationId: number(field('conversationId', 'conversation_id')),
      senderId: number(field('senderId', 'sender_id')),
      text: json['text'] as String? ?? '',
      sentAt:
          DateTime.tryParse(
            '${json['createdAt'] ?? json['created_at'] ?? json['sentAt']}',
          ) ??
          DateTime.now(),
      senderName: field('senderName', 'sender_name') as String? ?? '',
      senderAvatar: field('senderAvatar', 'sender_avatar') as String?,
      isRead: (field('isRead', 'is_read') as bool?) ?? false,
    );
  }
}
