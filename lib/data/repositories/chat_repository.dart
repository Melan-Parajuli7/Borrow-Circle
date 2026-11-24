import '../../data/models/chat_conversation.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/paged.dart';

/// Abstract contract for chat data access.
abstract class ChatRepository {
  /// Fetches the current user's conversations.
  Future<Paged<ChatConversation>> getConversations({int page = 1, int limit = 50});

  /// Fetches the messages of a conversation.
  Future<Paged<ChatMessage>> getMessages(int conversationId,
      {int page = 1, int limit = 50});

  /// Sends a message in a conversation.
  Future<ChatMessage> sendMessage(int conversationId, String text);

  /// Marks all messages of a conversation as read.
  Future<void> markRead(int conversationId);

  /// Starts (or finds an existing) conversation about an item/loan with a
  /// participant.
  Future<ChatConversation> startConversation(int participantId,
      {int? itemId, int? loanId});
}
