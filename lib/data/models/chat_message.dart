/// A single chat message exchanged between two users.
class ChatMessage {
  /// Unique identifier of the message.
  final int id;

  /// Conversation this message belongs to.
  final int conversationId;

  /// User who sent the message.
  final int senderId;

  /// Display name of the sender (denormalized by the API).
  final String senderName;

  /// Message body.
  final String text;

  /// Whether the message has been read by the recipient.
  final bool isRead;

  /// Timestamp when the message was sent.
  final DateTime createdAt;

  /// Creates a [ChatMessage] with the given properties.
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.isRead = false,
    required this.createdAt,
  });

  /// Creates a [ChatMessage] from a JSON map.
  ///
  /// Expects keys: `id`, `conversation_id`, `sender_id`, `sender_name`,
  /// `text`, `is_read`, `created_at`.
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: (j['id'] as num).toInt(),
        conversationId: (j['conversation_id'] as num).toInt(),
        senderId: (j['sender_id'] as num).toInt(),
        senderName: j['sender_name'] as String? ?? '',
        text: j['text'] as String? ?? '',
        isRead: j['is_read'] == true,
        createdAt: DateTime.tryParse('${j['created_at']}') ?? DateTime.now(),
      );

  /// Converts this [ChatMessage] into a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'sender_name': senderName,
        'text': text,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  /// Creates a copy of this message with [isRead] updated.
  ChatMessage copyWithRead(bool isRead) => ChatMessage(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        text: text,
        isRead: isRead,
        createdAt: createdAt,
      );
}
