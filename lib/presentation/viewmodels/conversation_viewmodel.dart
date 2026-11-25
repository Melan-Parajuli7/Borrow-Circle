import 'dart:async';

import '../../data/models/conversation_model.dart';
import '../../data/services/chat_service.dart';
import 'base_viewmodel.dart';

/// ViewModel for the conversation list.
///
/// Owns the Firestore stream of the current user's conversations and the
/// action of starting (or opening) a conversation with another user.
///
/// Depends on [ChatService]; pages never call Firestore directly.
class ConversationViewModel extends BaseViewModel {
  /// Creates a [ConversationViewModel] backed by [chatService].
  ConversationViewModel(this._chatService);

  /// Firestore chat service.
  final ChatService _chatService;

  /// The current user's stringified ID, set by [load].
  String? _currentUid;

  /// The current user's stringified ID, once [load] has been called.
  String? get currentUid => _currentUid;

  /// The current user's display name, used to denormalize participant names.
  String _currentName = '';

  /// The current user's conversations, most recent first.
  final List<ConversationModel> _conversations = [];

  /// The current user's conversations.
  List<ConversationModel> get conversations => _conversations;

  /// Stream subscription to the conversations stream, cancelled by [reset].
  StreamSubscription? _subscription;

  /// Loads and observes the current user's conversations.
  ///
  /// [currentUid] and [currentName] come from the authenticated session.
  Future<void> load(String currentUid, String currentName) async {
    reset();
    _currentUid = currentUid;
    _currentName = currentName;
    setLoading(true);
    try {
      _subscription = _chatService
          .conversationsStream(currentUid)
          .listen((conversations) {
        _conversations
          ..clear()
          ..addAll(conversations);
        notifyListeners();
      });
      setLoading(false);
    } catch (error) {
      setError(error.toString());
    }
  }

  /// Creates or returns the conversation with [otherUid], optionally about
  /// [itemId], and returns its [ConversationModel].
  ///
  /// The returned model is updated from Firestore once the stream emits it.
  Future<ConversationModel?> startConversation(
    String otherUid, {
    String? itemId,
  }) async {
    if (_currentUid == null) return null;
    setLoading(true);
    try {
      final id = await _chatService.createOrGetConversation(
        currentUid: _currentUid!,
        otherUid: otherUid,
        currentName: _currentName,
        otherName: otherUid,
        itemId: itemId,
      );
      return ConversationModel(
        id: id,
        participantIds: <String>[_currentUid!, otherUid],
        participantNames: <String, String>{
          _currentUid!: _currentName,
          otherUid: otherUid,
        },
        itemId: itemId,
      );
    } catch (error) {
      setError(error.toString());
      return null;
    } finally {
      setLoading(false);
    }
  }

  @override
  void reset() {
    _subscription?.cancel();
    _subscription = null;
    _conversations.clear();
    super.reset();
  }
}
