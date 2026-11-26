/// A conversation returned by the BorrowCircle chat API.
class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    this.loanId,
    this.itemId,
    this.itemTitle,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  final int id;
  final int participantId;
  final String participantName;
  final String? participantAvatar;
  final int? loanId;
  final int? itemId;
  final String? itemTitle;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  String otherParticipantId(String currentUid) => participantId.toString();

  String otherParticipantName(String currentUid) => participantName;

  bool get hasMessages => lastMessage != null;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    dynamic field(String camelCase, String snakeCase) =>
        json[camelCase] ?? json[snakeCase];
    int number(dynamic value) =>
        value is num ? value.toInt() : int.parse(value.toString());

    return ConversationModel(
      id: number(json['id']),
      participantId: number(field('participantId', 'participant_id')),
      participantName:
          field('participantName', 'participant_name') as String? ??
          'BorrowCircle user',
      participantAvatar:
          field('participantAvatar', 'participant_avatar') as String?,
      loanId: field('loanId', 'loan_id') == null
          ? null
          : number(field('loanId', 'loan_id')),
      itemId: field('itemId', 'item_id') == null
          ? null
          : number(field('itemId', 'item_id')),
      itemTitle: field('itemTitle', 'item_title') as String?,
      lastMessage: field('lastMessage', 'last_message') as String?,
      lastMessageAt: DateTime.tryParse(
        '${field('lastMessageAt', 'last_message_at')}',
      ),
      unreadCount: field('unreadCount', 'unread_count') == null
          ? 0
          : number(field('unreadCount', 'unread_count')),
    );
  }
}
