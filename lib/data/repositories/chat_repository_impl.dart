import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../data/models/chat_conversation.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/paged.dart';
import 'chat_repository.dart';

/// Concrete implementation of [ChatRepository] backed by the Express API.
class ChatRepositoryImpl implements ChatRepository {
  /// API client used to make authenticated HTTP requests.
  final ApiClient _apiClient;

  /// Creates a [ChatRepositoryImpl] with the given [apiClient].
  ChatRepositoryImpl(this._apiClient);

  @override
  Future<Paged<ChatConversation>> getConversations(
      {int page = 1, int limit = 50}) async {
    final json = await _apiClient.get(AppConstants.myChatsEndpoint,
        query: {'page': page, 'limit': limit});
    return Paged<ChatConversation>.fromJson(
        json, 'conversations', ChatConversation.fromJson);
  }

  @override
  Future<Paged<ChatMessage>> getMessages(int conversationId,
      {int page = 1, int limit = 50}) async {
    final json = await _apiClient.get(
        AppConstants.chatMessagesEndpoint(conversationId),
        query: {'page': page, 'limit': limit});
    return Paged<ChatMessage>.fromJson(
        json, 'messages', ChatMessage.fromJson);
  }

  @override
  Future<ChatMessage> sendMessage(int conversationId, String text) async {
    final json = await _apiClient.post(
      AppConstants.chatMessagesEndpoint(conversationId),
      body: {'text': text.trim()},
    );
    return ChatMessage.fromJson(json['message']);
  }

  @override
  Future<void> markRead(int conversationId) async {
    await _apiClient.patch(AppConstants.chatReadEndpoint(conversationId));
  }

  @override
  Future<ChatConversation> startConversation(int participantId,
      {int? itemId, int? loanId}) async {
    final body = <String, dynamic>{
      'participant_id': participantId,
      if (itemId != null) 'item_id': itemId,
      if (loanId != null) 'loan_id': loanId,
    };
    final json = await _apiClient.post(AppConstants.chatsEndpoint, body: body);
    return ChatConversation.fromJson(json['conversation']);
  }
}
