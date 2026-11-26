import 'package:flutter_test/flutter_test.dart';

import 'package:borrowcircle/data/models/conversation_model.dart';
import 'package:borrowcircle/data/models/message_model.dart';

void main() {
  group('ConversationModel.fromJson', () {
    test('parses API camelCase fields and timestamps', () {
      final conversation = ConversationModel.fromJson({
        'id': 12,
        'participantId': 7,
        'participantName': 'Rin',
        'lastMessage': 'Pickup at 3?',
        'lastMessageAt': '2026-11-26T08:00:00.000Z',
        'unreadCount': 2,
      });

      expect(conversation.id, 12);
      expect(conversation.otherParticipantId('4'), '7');
      expect(conversation.otherParticipantName('4'), 'Rin');
      expect(
        conversation.lastMessageAt,
        DateTime.parse('2026-11-26T08:00:00.000Z'),
      );
      expect(conversation.unreadCount, 2);
    });

    test('accepts snake_case fields from SQL-backed responses', () {
      final conversation = ConversationModel.fromJson({
        'id': '12',
        'participant_id': '7',
        'participant_name': 'Rin',
        'loan_id': 3,
      });

      expect(conversation.id, 12);
      expect(conversation.participantId, 7);
      expect(conversation.loanId, 3);
    });
  });

  test('MessageModel parses IDs and sender fields from API JSON', () {
    final message = MessageModel.fromJson({
      'id': 20,
      'conversation_id': 12,
      'sender_id': 7,
      'sender_name': 'Rin',
      'text': 'On my way',
      'created_at': '2026-11-26T08:00:00.000Z',
      'is_read': false,
    });

    expect(message.id, 20);
    expect(message.conversationId, 12);
    expect(message.isSentBy('7'), isTrue);
    expect(message.senderName, 'Rin');
    expect(message.sentAt, DateTime.parse('2026-11-26T08:00:00.000Z'));
  });
}
