import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/notification_model.dart';
import 'notification_repository.dart';

/// Concrete implementation of [NotificationRepository] using local storage.
///
/// Backend notification APIs can replace this implementation later.
class NotificationRepositoryImpl implements NotificationRepository {
  static const String _storageKey = 'borrowcircle_notifications';

  @override
  Future<List<NotificationModel>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? const [];
    return raw
        .map(
          (item) => NotificationModel.fromJson(
            jsonDecode(item) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  @override
  Future<void> save(List<NotificationModel> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      notifications.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}