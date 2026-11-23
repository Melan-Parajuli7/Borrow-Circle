import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:borrowcircle/model/notification_model.dart';

/// Frontend-only notification data service.
/// Backend notification APIs can replace this implementation later.
class NotificationService {
  static const _storageKey = 'borrowcircle_notifications';

  Future<List<NotificationModel>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_storageKey) ?? const [];
    return raw
        .map(
          (item) => NotificationModel.fromJson(
            jsonDecode(item) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> save(List<NotificationModel> notifications) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      notifications.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}
