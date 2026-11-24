import '../../data/models/notification_model.dart';

/// Abstract contract for notification data access.
abstract class NotificationRepository {
  /// Loads all notifications from local storage.
  Future<List<NotificationModel>> load();

  /// Saves notifications to local storage.
  Future<void> save(List<NotificationModel> notifications);
}