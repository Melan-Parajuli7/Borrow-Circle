import '../../data/models/group_model.dart';

/// Abstract contract for group data access.
abstract class GroupRepository {
  /// Fetches all groups on campus (built from group items).
  Future<List<GroupModel>> getGroups();

  /// Finds group items with the same title (for peer-to-group requests).
  Future<List<GroupModel>> findGroupAlternatives(String title);
}