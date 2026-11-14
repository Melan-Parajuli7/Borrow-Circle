import 'package:borrowcircle/model/group_model.dart';
import 'package:borrowcircle/model/item_model.dart';
import 'package:borrowcircle/services/item_service.dart';

/// The backend has no "groups" API. A group is simply the group_name written on
/// group items, so this service builds groups from the items list.
class GroupService {
  final ItemService _items = ItemService();

  /// Every group on campus (built from all group items).
  Future<List<GroupModel>> getGroups() async {
    final all = <ItemModel>[];
    var page = 1;
    while (true) {
      final result = await _items.getItems(page: page, limit: 50);
      all.addAll(result.data);
      if (!result.hasMore || page >= 5) break; // safety limit: 250 items
      page++;
    }
    return GroupModel.fromItems(all);
  }

  /// Group items with the SAME title as [title] (used by "Peer-to-Group" requests).
  /// Includes items that are on loan so the screen can show "All kits on loan".
  Future<List<ItemModel>> findGroupAlternatives(String title) async {
    final result = await _items.getItems(search: title, limit: 50);
    final wanted = title.trim().toLowerCase();
    return result.data
        .where((i) => i.isGroupItem && i.title.trim().toLowerCase() == wanted)
        .toList();
  }
}
