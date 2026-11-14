import 'item_model.dart';

/// The backend has no groups table: a group is just the "group_name" typed on
/// group items (e.g. "IoT Club"). This model is built on the phone by
/// grouping items with the same group_name.
class GroupModel {
  final String name;
  final List<ItemModel> items;

  const GroupModel({required this.name, required this.items});

  int get itemCount => items.length;
  int get availableCount => items.where((i) => i.isAvailable).length;

  /// Turns a flat list of items into groups (items without group_name are ignored).
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
