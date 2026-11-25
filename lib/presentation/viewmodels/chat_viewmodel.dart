import 'dart:async';

import '../../data/models/message_model.dart';
import '../../data/services/chat_service.dart';
import 'base_viewmodel.dart';

/// ViewModel for a single conversation: its messages and sending messages.
///
/// Depends on [ChatService]; the page never calls Firestore directly.
/// The ViewModel is scoped to one conversation page and should be disposed
/// when the page is popped.
class ChatViewModel extends BaseViewModel {
  /// Creates a [ChatViewModel] for [conversationId].
  ///
  /// [currentUid] is the stringified ID of the local user; [otherUid] and
  /// [otherName] identify the conversation partner.
  ChatViewModel({
    required ChatService chatService,
    required this.conversationId,
    required this.currentUid,
    required this.otherUid,
    this.otherName = '',
  }) : _chatService = chatService;

  /// Firestore chat service.
  final ChatService _chatService;

  /// ID of this conversation.
  final String conversationId;

  /// Stringified ID of the local user.
  final String currentUid;

  /// Stringified ID of the conversation partner.
  final String otherUid;

  /// Display name of the conversation partner.
  final String otherName;

  /// The conversation's messages, oldest first.
  final List<MessageModel> _messages = [];

  /// The conversation's messages.
  List<MessageModel> get messages => _messages;

  /// The partner's display name, falling back to their ID.
  String get partnerDisplayName => otherName.isNotEmpty ? otherName : otherUid;

  /// Stream subscription to the messages stream, cancelled by [dispose].
  StreamSubscription? _subscription;

  /// Loads and observes the messages of this conversation.
  Future<void> load() async {
    setLoading(true);
    try {
      _subscription = _chatService.messagesStream(conversationId).listen((messages) {
        _messages
          ..clear()
          ..addAll(messages);
        notifyListeners();
      });
      await _chatService.markRead(
        conversationId: conversationId,
        currentUid: currentUid,
      );
      setLoading(false);
    } catch (error) {
      setError(error.toString());
    }
  }

  /// Sends [text] to the conversation partner.
  ///
  /// Returns `true` when the message was written to Firestore; the stream
  /// delivers it back into [messages].
  Future<bool> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    setLoading(true);
    try {
      await _chatService.sendMessage(
        conversationId: conversationId,
        senderId: currentUid,
        recipientId: otherUid,
        text: trimmed,
      );
      setLoading(false);
      return true;
    } catch (error) {
      setError(error.toString());
      setLoading(false);
      return false;
    }
  }

  /// Marks messages sent by the partner as read.
  Future<void> markRead() async {
    await _chatService.markRead(
      conversationId: conversationId,
      currentUid: currentUid,
    );
  }

  /// Cancels the messages stream subscription.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _messages.clear();
  }
}
