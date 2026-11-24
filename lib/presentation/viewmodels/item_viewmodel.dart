import '../../data/models/item_model.dart';
import '../../data/repositories/item_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for item management (feed, search, my listings, CRUD).
class ItemViewModel extends BaseViewModel {
  final ItemRepository _repository;

  ItemViewModel(this._repository);

  // Feed state
  final List<ItemModel> _items = [];
  List<ItemModel> get items => _items;

  bool _hasMore = false;
  bool get hasMore => _hasMore;

  int _page = 1;

  // Filters
  String _search = '';
  String get search => _search;

  String? _category;
  String? get category => _category;

  String? _condition;
  String? get condition => _condition;

  bool _onlyAvailable = false;
  bool get onlyAvailable => _onlyAvailable;

  String _typeFilter = 'all'; // 'all' | 'peer' | 'group'
  String get typeFilter => _typeFilter;

  List<ItemModel> get visibleItems {
    if (_typeFilter == 'peer') return _items.where((i) => !i.isGroupItem).toList();
    if (_typeFilter == 'group') return _items.where((i) => i.isGroupItem).toList();
    return _items;
  }

  bool get hasActiveFilters => _category != null || _condition != null || _onlyAvailable;

  // My listings state
  final List<ItemModel> _myItems = [];
  List<ItemModel> get myItems => _myItems;

  int _myTotal = 0;
  int get myTotal => _myTotal;

  // Action state
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _actionError;
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
    _isSaving = true; // reuse isSaving for loadMore
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
  Future<bool> deleteItem(int id) async {
    return runWithLoading(() async {
      await _repository.deleteItem(id);
    });
  }

  /// Fetches a single item by ID.
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