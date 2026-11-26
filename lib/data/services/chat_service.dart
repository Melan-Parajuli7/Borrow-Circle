import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';

/// Local-only chat storage for UI previews; messages stay on this device.
class ChatService {
  ChatService(this._preferences);

  static const _storageKey = 'borrowcircle_local_chats_v1';
  static const _adminId = -1;

  final SharedPreferences _preferences;

  int _parseUserId(String userId) {
    final id = int.tryParse(userId);
    if (id == null || id <= 0) {
      throw ArgumentError.value(userId, 'userId', 'Expected a positive ID');
    }
    return id;
  }

  Future<List<Map<String, dynamic>>> _readConversations() async {
    final raw = _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Stored chat data is not a list');
    }
    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _saveConversations(
    List<Map<String, dynamic>> conversations,
  ) async {
    final saved = await _preferences.setString(
      _storageKey,
      jsonEncode(conversations),
    );
    if (!saved) throw StateError('Could not save local chat data');
  }

  Map<String, dynamic>? _findConversation(
    List<Map<String, dynamic>> conversations,
    int conversationId,
  ) {
    for (final conversation in conversations) {
      if (conversation['id'] == conversationId) return conversation;
    }
    return null;
  }

  bool _canAccess(Map<String, dynamic> conversation, int userId, String role) {
    if (conversation['kind'] == 'support' && role == 'admin') return true;
    return conversation['participant1Id'] == userId ||
        conversation['participant2Id'] == userId;
  }

  DateTime _activityTime(Map<String, dynamic> conversation) {
    final messages = conversation['messages'] as List<dynamic>? ?? const [];
    final timestamp = messages.isEmpty
        ? conversation['createdAt']
        : (messages.last as Map)['created_at'];
    return DateTime.tryParse('$timestamp') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  ConversationModel _toModel(
    Map<String, dynamic> conversation,
    int userId,
    String role,
  ) {
    final isSupport = conversation['kind'] == 'support';
    final otherId = isSupport
        ? (role == 'admin' ? conversation['supportUserId'] as int : _adminId)
        : (conversation['participant1Id'] == userId
              ? conversation['participant2Id'] as int
              : conversation['participant1Id'] as int);
    final otherName = isSupport
        ? (role == 'admin'
              ? conversation['supportUserName'] as String
              : 'BorrowCircle Admin')
        : (conversation['participant1Id'] == userId
              ? conversation['participant2Name'] as String
              : conversation['participant1Name'] as String);
    final messages = (conversation['messages'] as List<dynamic>? ?? const [])
        .cast<Map>();
    final lastMessage = messages.isEmpty
        ? null
        : Map<String, dynamic>.from(messages.last);
    final unreadCount = messages.where((message) {
      return message['sender_id'] != userId && message['is_read'] != true;
    }).length;

    return ConversationModel(
      id: conversation['id'] as int,
      participantId: otherId,
      participantName: otherName,
      loanId: conversation['loanId'] as int?,
      itemId: conversation['itemId'] as int?,
      itemTitle: conversation['itemTitle'] as String?,
      lastMessage: lastMessage?['text'] as String?,
      lastMessageAt: DateTime.tryParse('${lastMessage?['created_at']}'),
      unreadCount: unreadCount,
    );
  }

  Future<List<ConversationModel>> conversations({
    required String currentUserId,
    String role = 'user',
    int page = 1,
    int limit = 50,
  }) async {
    final userId = _parseUserId(currentUserId);
    final conversations = await _readConversations();
    final visible =
        conversations.where((conversation) {
          if (conversation['kind'] == 'support' && role == 'admin') return true;
          return conversation['participant1Id'] == userId ||
              conversation['participant2Id'] == userId;
        }).toList()..sort((first, second) {
          return _activityTime(second).compareTo(_activityTime(first));
        });

    final safePage = page > 0 ? page : 1;
    final safeLimit = limit > 0 ? limit : 50;
    final start = (safePage - 1) * safeLimit;
    if (start >= visible.length) return [];
    return visible
        .skip(start)
        .take(safeLimit)
        .map((conversation) => _toModel(conversation, userId, role))
        .toList();
  }

  Future<ConversationModel> startAdminConversation({
    required String currentUserId,
    required String userName,
  }) async {
    final userId = _parseUserId(currentUserId);
    final conversations = await _readConversations();
    var conversation = conversations.cast<Map<String, dynamic>?>().firstWhere(
      (item) =>
          item != null &&
          item['kind'] == 'support' &&
          item['supportUserId'] == userId,
      orElse: () => null,
    );

    if (conversation == null) {
      final nextId = conversations.fold<int>(
        1,
        (maximum, item) =>
            item['id'] as int >= maximum ? (item['id'] as int) + 1 : maximum,
      );
      conversation = {
        'id': nextId,
        'kind': 'support',
        'supportUserId': userId,
        'supportUserName': userName,
        'participant1Id': userId,
        'participant1Name': userName,
        'participant2Id': _adminId,
        'participant2Name': 'BorrowCircle Admin',
        'messages': <Map<String, dynamic>>[],
        'createdAt': DateTime.now().toIso8601String(),
      };
      conversations.add(conversation);
      await _saveConversations(conversations);
    }
    return _toModel(conversation, userId, 'user');
  }

  Future<ConversationModel> startLoanConversation({
    required int loanId,
    required String currentUserId,
    required String userName,
    required int otherUserId,
    required String otherUserName,
    required int itemId,
    required String itemTitle,
  }) async {
    final userId = _parseUserId(currentUserId);
    final conversations = await _readConversations();
    var conversation = conversations.cast<Map<String, dynamic>?>().firstWhere(
      (item) =>
          item != null && item['kind'] == 'loan' && item['loanId'] == loanId,
      orElse: () => null,
    );

    if (conversation == null) {
      final nextId = conversations.fold<int>(
        1,
        (maximum, item) =>
            item['id'] as int >= maximum ? (item['id'] as int) + 1 : maximum,
      );
      conversation = {
        'id': nextId,
        'kind': 'loan',
        'loanId': loanId,
        'itemId': itemId,
        'itemTitle': itemTitle,
        'participant1Id': userId,
        'participant1Name': userName,
        'participant2Id': otherUserId,
        'participant2Name': otherUserName,
        'messages': <Map<String, dynamic>>[],
        'createdAt': DateTime.now().toIso8601String(),
      };
      conversations.add(conversation);
      await _saveConversations(conversations);
    } else if (conversation['participant1Id'] != userId &&
        conversation['participant2Id'] != userId) {
      throw StateError('This loan conversation belongs to other participants');
    }
    return _toModel(conversation, userId, 'user');
  }

  Future<List<MessageModel>> messages({
    required int conversationId,
    required String currentUserId,
    String role = 'user',
  }) async {
    final userId = _parseUserId(currentUserId);
    final conversations = await _readConversations();
    final conversation = _findConversation(conversations, conversationId);
    if (conversation == null || !_canAccess(conversation, userId, role)) {
      throw StateError('This conversation is not available on this device');
    }
    final messages = (conversation['messages'] as List<dynamic>? ?? const [])
        .map(
          (message) =>
              MessageModel.fromJson(Map<String, dynamic>.from(message as Map)),
        )
        .toList();
    return messages;
  }

  Future<MessageModel> sendMessage({
    required int conversationId,
    required String currentUserId,
    required String senderName,
    required String text,
    String role = 'user',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 5000) {
      throw ArgumentError.value(
        text,
        'text',
        'Message must be 1-5000 characters',
      );
    }

    final userId = _parseUserId(currentUserId);
    final conversations = await _readConversations();
    final conversation = _findConversation(conversations, conversationId);
    if (conversation == null || !_canAccess(conversation, userId, role)) {
      throw StateError('This conversation is not available on this device');
    }
    final messages = conversation['messages'] as List<dynamic>;
    var nextMessageId = 1;
    for (final item in messages) {
      final id = (item as Map)['id'] as int;
      if (id >= nextMessageId) nextMessageId = id + 1;
    }
    final message = {
      'id': nextMessageId,
      'conversation_id': conversationId,
      'sender_id': userId,
      'sender_name': senderName,
      'text': trimmed,
      'created_at': DateTime.now().toIso8601String(),
      'is_read': false,
    };
    messages.add(message);
    await _saveConversations(conversations);
    return MessageModel.fromJson(message);
  }

  Future<void> markRead({
    required int conversationId,
    required String currentUserId,
    String role = 'user',
  }) async {
    final userId = _parseUserId(currentUserId);
    final conversations = await _readConversations();
    final conversation = _findConversation(conversations, conversationId);
    if (conversation == null || !_canAccess(conversation, userId, role)) {
      throw StateError('This conversation is not available on this device');
    }
    var changed = false;
    for (final message in conversation['messages'] as List<dynamic>) {
      final values = message as Map<String, dynamic>;
      if (values['sender_id'] != userId && values['is_read'] != true) {
        values['is_read'] = true;
        changed = true;
      }
    }
    if (changed) await _saveConversations(conversations);
  }
}
