import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Firestore service for conversations and messages.
///
/// All chat data lives in Firestore:
/// - `conversations/{conversationId}`: participantIds, participantNames,
///   lastMessage, lastMessageAt, itemId
/// - `conversations/{conversationId}/messages/{messageId}`: senderId, text,
///   sentAt, isRead
///
/// Pages never call Firestore directly: a ViewModel owns the calls to this
/// service.
class ChatService {
  /// Creates a [ChatService] backed by [firestore] (defaults to the default
  /// Firebase Firestore instance).
  ChatService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Conversation ID for two participants: their stringified IDs sorted and
  /// joined with `_`, so `A-B` and `B-A` resolve to the same conversation.
  String conversationIdFor(String uidA, String uidB) {
    final ids = <String>[uidA, uidB]..sort();
    return ids.join('_');
  }

  /// Stream of [currentUid]'s conversations, most recent first.
  Stream<List<ConversationModel>> conversationsStream(String currentUid) {
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: currentUid)
        .snapshots()
        .map((snapshot) {
          final conversations = snapshot.docs
              .map(ConversationModel.fromSnapshot)
              .toList();
          conversations.sort((a, b) {
            final da = a.lastMessageAt ?? _epoch;
            final db = b.lastMessageAt ?? _epoch;
            return db.compareTo(da);
          });
          return conversations;
        });
  }

  /// Zero-based timestamp used when a conversation has no last message yet.
  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);

  /// Creates or returns the conversation between [currentUid] and [otherUid].
  ///
  /// [currentName] and [otherName] are denormalized into
  /// `participantNames` so the tile can show a name without extra lookups.
  /// [itemId] links the conversation to an item listing, if any.
  Future<String> createOrGetConversation({
    required String currentUid,
    required String otherUid,
    required String currentName,
    required String otherName,
    String? itemId,
  }) async {
    final conversationId = conversationIdFor(currentUid, otherUid);
    final ref = _firestore.collection('conversations').doc(conversationId);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      await ref.set(<String, dynamic>{
        'participantIds': <String>[currentUid, otherUid],
        'participantNames': <String, String>{
          currentUid: currentName,
          otherUid: otherName,
        },
        if (itemId != null) 'itemId': itemId,
        'lastMessage': null,
        'lastMessageAt': null,
      });
    } else {
      // Keep participant names up to date whenever the conversation is opened.
      await ref.update(<String, dynamic>{
        'participantNames': <String, String>{
          currentUid: currentName,
          otherUid: otherName,
        },
      });
    }
    return conversationId;
  }

  /// Stream of messages in [conversationId], oldest first.
  Stream<List<MessageModel>> messagesStream(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(MessageModel.fromSnapshot).toList(),
        );
  }

  /// Sends [text] from [senderId] to [recipientId] in [conversationId].
  ///
  /// The message and the conversation's `lastMessage`/`lastMessageAt` are
  /// written in a single transaction.
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String recipientId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final conversationRef =
        _firestore.collection('conversations').doc(conversationId);
    final messageRef = conversationRef.collection('messages').doc();

    await _firestore.runTransaction((transaction) async {
      transaction.set(messageRef, <String, dynamic>{
        'conversationId': conversationId,
        'senderId': senderId,
        'text': trimmed,
        'sentAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      transaction.update(conversationRef, <String, dynamic>{
        'lastMessage': trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Marks all messages in [conversationId] sent by others as read.
  Future<void> markRead({
    required String conversationId,
    required String currentUid,
  }) async {
    final snapshot = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, <String, dynamic>{'isRead': true});
    }
    await batch.commit();
  }
}
