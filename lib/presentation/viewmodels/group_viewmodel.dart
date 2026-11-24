import '../../data/models/group_model.dart';
import '../../data/models/item_model.dart';
import '../../data/repositories/group_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for group management.
class GroupViewModel extends BaseViewModel {
  final GroupRepository _repository;

  GroupViewModel(this._repository);

  final List<GroupModel> _groups = [];
  List<GroupModel> get groups => _groups;

  /// Loads all groups.
  Future<void> load() async {
    await runWithLoading(() async {
      _groups
        ..clear()
        ..addAll(await _repository.getGroups());
    });
  }

  /// Groups where the user listed at least one item (acts as coordinator).
  List<GroupModel> managedBy(int userId) =>
      _groups.where((g) => g.items.any((i) => i.ownerId == userId)).toList();

  /// Groups where the user has no items.
  List<GroupModel> othersFor(int userId) =>
      _groups.where((g) => !g.items.any((i) => i.ownerId == userId)).toList();

  /// Finds group items that match the given [title].
  ///
  /// Used on the item details screen to suggest group-owned alternatives for a
  /// peer item. Returns a flattened list of [ItemModel] drawn from matching
  /// groups. Returns an empty list on failure.
  Future<List<ItemModel>> findGroupAlternatives(String title) async {
    try {
      final groups = await _repository.findGroupAlternatives(title);
      return groups.expand((g) => g.items).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  void reset() {
    super.reset();
    _groups.clear();
  }
}