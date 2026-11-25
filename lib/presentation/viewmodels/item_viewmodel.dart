import '../../data/models/item_model.dart';
import '../../data/repositories/item_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for item management (feed, search, my listings, CRUD).
///
/// Holds the item feed, the user's own listings, and active filters.
/// Delegates all data operations to the [ItemRepository].
class ItemViewModel extends BaseViewModel {
  /// Creates an [ItemViewModel] backed by [repository].
  ItemViewModel(this._repository);

  /// Repository used to perform item CRUD and feed operations.
  final ItemRepository _repository;

  // Feed state
  final List<ItemModel> _items = [];
  /// The full list of items for the current feed.
  List<ItemModel> get items => _items;

  bool _hasMore = false;
  /// Whether more pages of the feed are available.
  bool get hasMore => _hasMore;

  int _page = 1;

  // Filters
  String _search = '';
  /// Current search query.
  String get search => _search;

  String? _category;
  /// Currently selected category filter, if any.
  String? get category => _category;

  String? _condition;
  /// Currently selected condition filter, if any.
  String? get condition => _condition;

  bool _onlyAvailable = false;
  /// Whether only available items are shown.
  bool get onlyAvailable => _onlyAvailable;

  String _typeFilter = 'all'; // 'all' | 'peer' | 'group'
  /// Current type filter: 'all', 'peer', or 'group'.
  String get typeFilter => _typeFilter;

  /// Items matching the current type filter.
  List<ItemModel> get visibleItems {
    if (_typeFilter == 'peer') return _items.where((i) => !i.isGroupItem).toList();
    if (_typeFilter == 'group') return _items.where((i) => i.isGroupItem).toList();
    return _items;
  }

  /// Whether any filters (category, condition, availability) are active.
  bool get hasActiveFilters => _category != null || _condition != null || _onlyAvailable;

  // My listings state
  final List<ItemModel> _myItems = [];
  /// The current user's own item listings.
  List<ItemModel> get myItems => _myItems;

  int _myTotal = 0;
  /// Total number of the user's own listings.
  int get myTotal => _myTotal;

  // Action state
  bool _isSaving = false;
  /// Whether a save (create/update) operation is in progress.
  bool get isSaving => _isSaving;

  String? _actionError;
  /// Error from the last item action, if any.
  String? get actionError => _actionError;

  /// Loads the item feed (first page).
  Future<void> load() async {
    await runWithLoading(() async {
      _page = 1;
      final result = await _repository.getItems(
        search: _search,
        category: _category,
        condition: _condition,
        available: _onlyAvailable ? true : null,
        page: 1,
        limit: 10,
      );
      _items
        ..clear()
        ..addAll(result.data);
      _hasMore = result.hasMore;
    });
  }

  /// Loads the next page of the feed.
  Future<void> loadMore() async {
    if (isLoading || _isSaving || !_hasMore) return;
    _isSaving = true;
    notifyListeners();
    try {
      final result = await _repository.getItems(
        search: _search,
        category: _category,
        condition: _condition,
        available: _onlyAvailable ? true : null,
        page: _page + 1,
        limit: 10,
      );
      _page++;
      _items.addAll(result.data);
      _hasMore = result.hasMore;
    } catch (_) {
      // Keep what we already have
    }
    _isSaving = false;
    notifyListeners();
  }

  /// Sets the type filter and reloads.
  void setType(String type) {
    _typeFilter = type;
    notifyListeners();
  }

  /// Sets the search query and reloads.
  Future<void> setSearch(String text) async {
    _search = text.trim();
    await load();
  }

  /// Applies filters and reloads.
  Future<void> applyFilters({
    String? category,
    String? condition,
    required bool onlyAvailable,
  }) async {
    _category = category;
    _condition = condition;
    _onlyAvailable = onlyAvailable;
    await load();
  }

  /// Loads the current user's listings.
  Future<void> loadMine() async {
    await runWithLoading(() async {
      final result = await _repository.getMyItems();
      _myItems
        ..clear()
        ..addAll(result.data);
      _myTotal = result.total;
    });
  }

  /// Creates a new item.
  ///
  /// Returns the created [ItemModel] on success, or `null` on failure.
  Future<ItemModel?> createItem({
    required String title,
    String? description,
    String? category,
    required String condition,
    required bool isGroupItem,
    String? groupName,
    String? imagePath,
  }) async {
    return runWithLoadingValue(() async {
      return await _repository.createItem(
        title: title,
        description: description,
        category: category,
        condition: condition,
        isGroupItem: isGroupItem,
        groupName: groupName,
        imagePath: imagePath,
      );
    });
  }

  /// Updates an existing item.
  ///
  /// Returns the updated [ItemModel] on success, or `null` on failure.
  Future<ItemModel?> updateItem(
    int id, {
    required String title,
    String? description,
    String? category,
    required String condition,
    required bool isGroupItem,
    String? groupName,
    bool? isAvailable,
    String? imagePath,
  }) async {
    return runWithLoadingValue(() async {
      return await _repository.updateItem(
        id,
        title: title,
        description: description,
        category: category,
        condition: condition,
        isGroupItem: isGroupItem,
        groupName: groupName,
        isAvailable: isAvailable,
        imagePath: imagePath,
      );
    });
  }

  /// Deletes an item.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> deleteItem(int id) async {
    return runWithLoading(() async {
      await _repository.deleteItem(id);
    });
  }

  /// Fetches a single item by ID.
  ///
  /// Returns the [ItemModel] on success, or `null` on failure.
  Future<ItemModel?> getItem(int id) async {
    return runWithLoadingValue(() async {
      return await _repository.getItem(id);
    });
  }

  @override
  void reset() {
    super.reset();
    _items.clear();
    _myItems.clear();
    _myTotal = 0;
    _search = '';
    _category = null;
    _condition = null;
    _onlyAvailable = false;
    _typeFilter = 'all';
    _hasMore = false;
    _page = 1;
    _isSaving = false;
    _actionError = null;
  }
}
