import 'dart:async';

import '../../data/models/conversation_model.dart';
import '../../data/services/chat_service.dart';
import 'base_viewmodel.dart';

/// ViewModel for the user's conversation list and chat entry actions.
class ConversationViewModel extends BaseViewModel {
  ConversationViewModel(this._chatService);

  final ChatService _chatService;
  String? _currentUid;
  String _currentRole = 'user';
  String? get currentUid => _currentUid;

  final List<ConversationModel> _conversations = [];
  List<ConversationModel> get conversations => _conversations;

  Timer? _refreshTimer;
  bool _isRefreshing = false;
  bool _disposed = false;

  Future<void> load(String currentUid, {String role = 'user'}) async {
    if (_currentUid != currentUid || _currentRole != role) {
      _refreshTimer?.cancel();
      _conversations.clear();
    }
    _currentUid = currentUid;
    _currentRole = role;
    setBusy(true);
    await refresh();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => refresh(),
    );
  }

  Future<void> refresh() async {
    if (_isRefreshing || _disposed) return;
    _isRefreshing = true;
    try {
      final currentUid = _currentUid;
      if (currentUid == null) return;
      final conversations = await _chatService.conversations(
        currentUserId: currentUid,
        role: _currentRole,
      );
      if (_disposed) return;
      _conversations
        ..clear()
        ..addAll(conversations);
      setBusy(false);
    } catch (error) {
      if (!_disposed) setError(error.toString());
    } finally {
      _isRefreshing = false;
    }
  }

  Future<ConversationModel?> startLoanConversation({
    required int loanId,
    required String currentUserId,
    required String userName,
    required int otherUserId,
    required String otherUserName,
    required int itemId,
    required String itemTitle,
  }) => _start(
    () => _chatService.startLoanConversation(
      loanId: loanId,
      currentUserId: currentUserId,
      userName: userName,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      itemId: itemId,
      itemTitle: itemTitle,
    ),
  );

  Future<ConversationModel?> startAdminConversation({
    required String currentUserId,
    required String userName,
  }) => _start(
    () => _chatService.startAdminConversation(
      currentUserId: currentUserId,
      userName: userName,
    ),
  );

  Future<ConversationModel?> _start(
    Future<ConversationModel> Function() action,
  ) async {
    setBusy(true);
    try {
      final conversation = await action();
      final index = _conversations.indexWhere(
        (item) => item.id == conversation.id,
      );
      if (index == -1) {
        _conversations.insert(0, conversation);
      } else {
        _conversations[index] = conversation;
      }
      notifyListeners();
      await refresh();
      return conversation;
    } catch (error) {
      setError(error.toString());
      return null;
    } finally {
      if (!_disposed) setBusy(false);
    }
  }

  @override
  void reset() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _currentUid = null;
    _currentRole = 'user';
    _conversations.clear();
    super.reset();
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    super.dispose();
  }
}
