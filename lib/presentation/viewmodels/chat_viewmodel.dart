import '../../data/models/chat_conversation.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for chat (conversations and messages).
class ChatViewModel extends BaseViewModel {
  final ChatRepository _repository;

  ChatViewModel(this._repository);

  final List<ChatConversation> _conversations = [];
  List<ChatConversation> get conversations => _conversations;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  int _conversationPage = 1;
  bool _conversationsHasMore = true;

  /// Zero-based timestamp used when a conversation has no last message yet.
  static final _epoch = DateTime(1970);

  int get unreadConversations =>
      _conversations.where((c) => c.hasUnread).length;

  /// Loads the current user's conversations (first page).
  Future<void> loadConversations({bool refresh = false}) async {
    if (refresh) {
      _conversations.clear();
      _conversationPage = 1;
      _conversationsHasMore = true;
    }
    if (!_conversationsHasMore) return;
    await runWithLoading(() async {
      final result = await _repository.getConversations(
          page: _conversationPage);
      _conversations.addAll(result.data);
      _conversations.sort((a, b) {
        final da = a.lastMessageAt ?? _epoch;
        final db = b.lastMessageAt ?? _epoch;
        return db.compareTo(da);
      });
      _conversationPage++;
      _conversationsHasMore = result.hasMore;
    });
  }

  /// Loads the messages of [conversationId].
  Future<void> loadMessages(int conversationId,
      {int page = 1, bool refresh = false}) async {
    if (refresh) {
      _messages.clear();
    }
    await runWithLoading(() async {
      final result = await _repository.getMessages(conversationId, page: page);
      if (page == 1) {
        _messages
          ..clear()
          ..addAll(result.data.reversed);
      } else {
        _messages.insertAll(0, result.data.reversed);
      }
    });
  }

  /// Sends [text] in [conversationId] and appends it locally.
  Future<ChatMessage?> sendMessage(int conversationId, String text) async {
    return runWithLoadingValue(() async {
      final message = await _repository.sendMessage(conversationId, text);
      _messages.add(message);
      notifyListeners();
      return message;
    });
  }

  /// Marks [conversationId] as read (server + local).
  Future<void> markRead(int conversationId) async {
    await _repository.markRead(conversationId);
    _messages
      ..clear()
      ..addAll(_messages.map((m) => m.copyWithRead(true)));
    _conversations
      ..clear()
      ..addAll(_conversations.map((c) =>
          c.id == conversationId ? c.copyWithUnread(0) : c));
    notifyListeners();
  }

  /// Starts (or finds) a conversation with [participantId], optionally about an
  /// item or loan, then loads its messages.
  Future<ChatConversation?> startConversation(int participantId,
      {int? itemId, int? loanId}) async {
    return runWithLoadingValue(() async {
      final conversation = await _repository.startConversation(
          participantId, itemId: itemId, loanId: loanId);
      await loadMessages(conversation.id, refresh: true);
      await loadConversations(refresh: true);
      return conversation;
    });
  }

  @override
  void reset() {
    super.reset();
    _conversations.clear();
    _messages.clear();
    _conversationPage = 1;
    _conversationsHasMore = true;
  }
}
