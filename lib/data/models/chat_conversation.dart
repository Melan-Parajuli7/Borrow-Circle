/// A conversation between the current user and another participant.
class ChatConversation {
  /// Unique identifier of the conversation.
  final int id;

  /// The other participant's user ID.
  final int participantId;

  /// The other participant's display name.
  final String participantName;

  /// The other participant's avatar file name, if any.
  final String? participantAvatar;

  /// The item the conversation is about, if any.
  final int? itemId;

  /// Title of the item the conversation is about, if any.
  final String? itemTitle;

  /// Preview of the most recent message.
  final String? lastMessage;

  /// Timestamp of the most recent message.
  final DateTime? lastMessageAt;

  /// Number of unread messages in this conversation.
  final int unreadCount;

  /// Creates a [ChatConversation] with the given properties.
  const ChatConversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    this.itemId,
    this.itemTitle,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  /// Creates a [ChatConversation] from a JSON map.
  ///
  /// Expects keys: `id`, `participant_id`, `participant_name`,
  /// `participant_avatar`, `item_id`, `item_title`, `last_message`,
  /// `last_message_at`, `unread_count`.
  factory ChatConversation.fromJson(Map<String, dynamic> j) =>
      ChatConversation(
        id: (j['id'] as num).toInt(),
        participantId: (j['participant_id'] as num).toInt(),
        participantName: j['participant_name'] as String? ?? '',
        participantAvatar: j['participant_avatar'] as String?,
        itemId: (j['item_id'] as num?)?.toInt(),
        itemTitle: j['item_title'] as String?,
        lastMessage: j['last_message'] as String?,
        lastMessageAt: DateTime.tryParse('${j['last_message_at']}'),
        unreadCount: (j['unread_count'] as num?)?.toInt() ?? 0,
      );

  /// Converts this [ChatConversation] into a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'participant_id': participantId,
        'participant_name': participantName,
        'participant_avatar': participantAvatar,
        'item_id': itemId,
        'item_title': itemTitle,
        'last_message': lastMessage,
        'last_message_at': lastMessageAt?.toIso8601String(),
        'unread_count': unreadCount,
      };

  /// Whether this conversation has unread messages.
  bool get hasUnread => unreadCount > 0;

  /// Creates a copy of this conversation with [unreadCount] updated.
  ChatConversation copyWithUnread(int unreadCount) => ChatConversation(
        id: id,
        participantId: participantId,
        participantName: participantName,
        participantAvatar: participantAvatar,
        itemId: itemId,
        itemTitle: itemTitle,
        lastMessage: lastMessage,
        lastMessageAt: lastMessageAt,
        unreadCount: unreadCount,
      );
}
