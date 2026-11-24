import '../../core/network/api_client.dart';
import '../../data/models/group_model.dart';
import '../../data/models/item_model.dart';
import 'group_repository.dart';
import 'item_repository_impl.dart';

/// Concrete implementation of [GroupRepository].
///
/// The backend has no dedicated groups API. Groups are built client-side
/// by aggregating items that share the same group_name.
class GroupRepositoryImpl implements GroupRepository {
  /// Repository used to page through the item feed.
  final ItemRepositoryImpl _items;

  /// Creates a [GroupRepositoryImpl] with the given [apiClient].
  GroupRepositoryImpl(ApiClient apiClient) : _items = ItemRepositoryImpl(apiClient);

  @override
  Future<List<GroupModel>> getGroups() async {
    final all = <ItemModel>[];
    var page = 1;
    while (true) {
      final result = await _items.getItems(page: page, limit: 50);
      all.addAll(result.data);
      if (!result.hasMore || page >= 5) break; // Safety limit: 250 items
      page++;
    }
    return GroupModel.fromItems(all);
  }

  @override
  Future<List<GroupModel>> findGroupAlternatives(String title) async {
    final result = await _items.getItems(search: title, limit: 50);
    final wanted = title.trim().toLowerCase();
    final items = result.data
        .where((i) =>
            i.isGroupItem && i.title.trim().toLowerCase() == wanted)
        .toList();
    return GroupModel.fromItems(items);
  }
}