import 'item_model.dart';

/// Group model representing a campus group (built from group items).
///
/// The backend has no dedicated groups table; a group is simply the [name]
/// typed on group items. This model aggregates items sharing the same group name.
class GroupModel {
  /// Name of the group (e.g., "IoT Club").
  final String name;

  /// Items belonging to this group.
  final List<ItemModel> items;

  /// Creates a [GroupModel] with the given [name] and [items].
  const GroupModel({required this.name, required this.items});

  /// Number of items in this group.
  int get itemCount => items.length;

  /// Number of available items in this group.
  int get availableCount => items.where((i) => i.isAvailable).length;

  /// Turns a flat list of items into groups.
  ///
  /// Items without a group name or where [ItemModel.isGroupItem] is false are ignored.
  /// The resulting list is sorted alphabetically by group name.
  static List<GroupModel> fromItems(List<ItemModel> items) {
    final map = <String, List<ItemModel>>{};
    for (final item in items) {
      final name = item.groupName?.trim();
      if (!item.isGroupItem || name == null || name.isEmpty) continue;
      map.putIfAbsent(name, () => []).add(item);
    }
    final groups = map.entries
        .map((e) => GroupModel(name: e.key, items: e.value))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return groups;
  }
}