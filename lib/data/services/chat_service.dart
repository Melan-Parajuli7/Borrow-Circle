import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// HTTP service for conversations and messages.
class ChatService {
  ChatService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ConversationModel>> conversations({
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _apiClient.get(
      AppConstants.chatsEndpoint,
      query: {'page': page, 'limit': limit},
    );
    final data = response['conversations'] as List<dynamic>? ?? const [];
    return data
        .map(
          (item) => ConversationModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<ConversationModel> startLoanConversation(int loanId) async {
    final response = await _apiClient.post(
      AppConstants.startLoanChatEndpoint(loanId),
    );
    return ConversationModel.fromJson(
      Map<String, dynamic>.from(response['conversation'] as Map),
    );
  }

  Future<ConversationModel> startAdminConversation() async {
    final response = await _apiClient.post(AppConstants.startAdminChatEndpoint);
    return ConversationModel.fromJson(
      Map<String, dynamic>.from(response['conversation'] as Map),
    );
  }

  Future<List<MessageModel>> messages(
    int conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _apiClient.get(
      AppConstants.chatMessagesEndpoint(conversationId),
      query: {'page': page, 'limit': limit},
    );
    final data = response['messages'] as List<dynamic>? ?? const [];
    return data
        .map(
          (item) =>
              MessageModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<MessageModel> sendMessage(int conversationId, String text) async {
    final response = await _apiClient.post(
      AppConstants.chatMessagesEndpoint(conversationId),
      body: {'text': text},
    );
    return MessageModel.fromJson(
      Map<String, dynamic>.from(response['message'] as Map),
    );
  }

  Future<void> markRead(int conversationId) async {
    await _apiClient.patch(AppConstants.chatReadEndpoint(conversationId));
  }
}
