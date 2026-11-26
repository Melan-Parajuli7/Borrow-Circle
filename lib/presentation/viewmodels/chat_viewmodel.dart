import 'dart:async';

import '../../data/models/message_model.dart';
import '../../data/services/chat_service.dart';
import 'base_viewmodel.dart';

/// ViewModel for a single conversation.
class ChatViewModel extends BaseViewModel {
  ChatViewModel({
    required this.chatService,
    required this.conversationId,
    required this.currentUid,
    required this.otherUid,
    this.otherName = '',
  });

  final ChatService chatService;
  final int conversationId;
  final String currentUid;
  final String otherUid;
  final String otherName;

  final List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  String get partnerDisplayName => otherName.isNotEmpty ? otherName : otherUid;

  Timer? _refreshTimer;
  bool _isRefreshing = false;
  bool _disposed = false;

  Future<void> load() async {
    setBusy(true);
    await refresh();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => refresh(),
    );
  }

  Future<void> refresh() async {
    if (_isRefreshing || _disposed) return;
    _isRefreshing = true;
    try {
      final messages = await chatService.messages(conversationId);
      if (_disposed) return;
      _messages
        ..clear()
        ..addAll(messages);
      if (_messages.any(
        (message) => !message.isRead && !message.isSentBy(currentUid),
      )) {
        await chatService.markRead(conversationId);
      }
      if (!_disposed) setBusy(false);
    } catch (error) {
      if (!_disposed) setError(error.toString());
    } finally {
      _isRefreshing = false;
    }
  }

  Future<bool> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _disposed) return false;
    setBusy(true);
    try {
      final message = await chatService.sendMessage(conversationId, trimmed);
      if (_disposed) return false;
      _messages.add(message);
      setBusy(false);
      return true;
    } catch (error) {
      if (!_disposed) setError(error.toString());
      return false;
    }
  }

  Future<void> markRead() => chatService.markRead(conversationId);

  @override
  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    super.dispose();
  }
}
