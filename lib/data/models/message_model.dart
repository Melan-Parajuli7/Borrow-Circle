import 'package:cloud_firestore/cloud_firestore.dart';

/// A message inside a Firestore conversation.
///
/// Document path: `conversations/{conversationId}/messages/{messageId}`.
///
/// Fields:
/// - `senderId`: stringified ID of the sender
/// - `text`: message body
/// - `sentAt`: timestamp when the message was sent
/// - `isRead`: whether the recipient has read it
class MessageModel {
  /// Creates a [MessageModel] with the given properties.
  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.isRead = false,
  });

  /// Firestore document ID.
  final String id;

  /// Conversation this message belongs to.
  final String conversationId;

  /// Stringified ID of the user who sent the message.
  final String senderId;

  /// Message body.
  final String text;

  /// Timestamp when the message was sent.
  final DateTime sentAt;

  /// Whether the message has been read by the recipient.
  final bool isRead;

  /// Whether this message was sent by [uid].
  bool isSentBy(String uid) => senderId == uid;

  /// Creates a [MessageModel] from a Firestore snapshot.
  factory MessageModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return MessageModel(
      id: snapshot.id,
      conversationId: (data['conversationId'] as String?) ?? '',
      senderId: (data['senderId'] as String?) ?? '',
      text: (data['text'] as String?) ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: (data['isRead'] as bool?) ?? false,
    );
  }

  /// Converts this [MessageModel] into a Firestore map.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'conversationId': conversationId,
        'senderId': senderId,
        'text': text,
        'sentAt': Timestamp.fromDate(sentAt),
        'isRead': isRead,
      };

  /// Creates a copy with [isRead] updated.
  MessageModel copyWithRead(bool isRead) => MessageModel(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        text: text,
        sentAt: sentAt,
        isRead: isRead,
      );
}
