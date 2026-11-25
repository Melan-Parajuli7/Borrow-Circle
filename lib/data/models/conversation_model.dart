import 'package:cloud_firestore/cloud_firestore.dart';

/// A conversation between two users stored in Firestore.
///
/// Document path: `conversations/{conversationId}`.
///
/// Fields:
/// - `participantIds`: stringified IDs of the two participants
/// - `participantNames`: participant ID → display name (denormalized for the tile)
/// - `lastMessage`: preview of the most recent message
/// - `lastMessageAt`: timestamp of the most recent message
/// - `itemId`: item the conversation is about, if any
class ConversationModel {
  /// Creates a [ConversationModel] with the given properties.
  ConversationModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    this.lastMessage,
    this.lastMessageAt,
    this.itemId,
  });

  /// Firestore document ID.
  final String id;

  /// Stringified IDs of the two participants.
  final List<String> participantIds;

  /// Participant ID → display name, denormalized for the conversation tile.
  final Map<String, String> participantNames;

  /// Preview of the most recent message, if any.
  final String? lastMessage;

  /// Timestamp of the most recent message, if any.
  final DateTime? lastMessageAt;

  /// Item the conversation is about, if any.
  final String? itemId;

  /// ID of the participant other than [currentUid].
  String otherParticipantId(String currentUid) {
    for (final id in participantIds) {
      if (id != currentUid) return id;
    }
    return participantIds.isNotEmpty ? participantIds.first : '';
  }

  /// Display name of the participant other than [currentUid].
  String otherParticipantName(String currentUid) {
    final other = otherParticipantId(currentUid);
    return participantNames[other] ?? other;
  }

  /// Whether any messages have been exchanged yet.
  bool get hasMessages => lastMessage != null;

  /// Creates a [ConversationModel] from a Firestore snapshot.
  factory ConversationModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return ConversationModel(
      id: snapshot.id,
      participantIds: (data['participantIds'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          <String>[],
      participantNames: (data['participantNames'] as Map<dynamic, dynamic>?)
              ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
          <String, String>{},
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      itemId: data['itemId'] as String?,
    );
  }

  /// Converts this [ConversationModel] into a Firestore map.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'participantIds': participantIds,
        'participantNames': participantNames,
        if (lastMessage != null) 'lastMessage': lastMessage,
        if (lastMessageAt != null)
          'lastMessageAt': Timestamp.fromDate(lastMessageAt!),
        if (itemId != null) 'itemId': itemId,
      };

  /// Creates a copy with the given fields replaced.
  ConversationModel copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
  }) {
    return ConversationModel(
      id: id,
      participantIds: participantIds,
      participantNames: participantNames,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      itemId: itemId,
    );
  }
}
