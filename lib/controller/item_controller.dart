import 'package:flutter/foundation.dart';

import 'package:borrowcircle/model/item_model.dart';
import 'package:borrowcircle/services/api_service.dart';
import 'package:borrowcircle/services/item_service.dart';

/// Items feed (Home), search / filters, my listings, and create / edit / delete.
class ItemController extends ChangeNotifier {
  final ItemService _service = ItemService();

  // ---------- feed ----------
  List<ItemModel> items = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = false;
  String? error;
  int _page = 1;

  String search = '';
  String? category;
  String? condition;
  bool onlyAvailable = false;

  /// 'all' | 'peer' | 'group'   (the tabs on Home)
  String typeFilter = 'all';

  List<ItemModel> get visibleItems {
    if (typeFilter == 'peer') return items.where((i) => !i.isGroupItem).toList();
    if (typeFilter == 'group') return items.where((i) => i.isGroupItem).toList();
    return items;
  }

  bool get hasActiveFilters => category != null || condition != null || onlyAvailable;

  Future<void> load() async {
    isLoading = true;
    error = null;
    _page = 1;
    notifyListeners();
    try {
      final r = await _service.getItems(
        search: search,
        category: category,
        condition: condition,
        available: onlyAvailable ? true : null,
        page: 1,
        limit: 10,
      );
      items = r.data;
      hasMore = r.hasMore;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not load items.';
    }
    isLoading = false;
    notifyListeners();
  }

  /// Called when the user scrolls to the bottom.
  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMore) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final r = await _service.getItems(
        search: search,
        category: category,
        condition: condition,
        available: onlyAvailable ? true : null,
        page: _page + 1,
        limit: 10,
      );
      _page++;
      items = [...items, ...r.data];
      hasMore = r.hasMore;
    } catch (_) {
      // keep what we already have
    }
    isLoadingMore = false;
    notifyListeners();
  }

  void setType(String type) {
    typeFilter = type;
    notifyListeners();
  }

  Future<void> setSearch(String text) {
    search = text.trim();
    return load();
  }

  Future<void> applyFilters({String? category, String? condition, required bool onlyAvailable}) {
    this.category = category;
    this.condition = condition;
    this.onlyAvailable = onlyAvailable;
    return load();
  }

  // ---------- my listings ----------
  List<ItemModel> myItems = [];
  int myTotal = 0;
  bool isLoadingMine = false;
  String? mineError;

  Future<void> loadMine() async {
    isLoadingMine = true;
    mineError = null;
    notifyListeners();
    try {
      final r = await _service.getMyItems();
      myItems = r.data;
      myTotal = r.total;
    } on ApiException catch (e) {
      mineError = e.message;
    } catch (_) {
      mineError = 'Could not load your items.';
    }
    isLoadingMine = false;
    notifyListeners();
  }

  // ---------- create / edit / delete ----------
  bool isSaving = false;
  String? actionError;

  Future<ItemModel?> createItem({
    required String title,
    String? description,
    String? category,
    required String condition,
    required bool isGroupItem,
    String? groupName,
    String? imagePath,
  }) async {
    ItemModel? created;
    final ok = await _act(() async {
      created = await _service.createItem(
        title: title,
        description: description,
        category: category,
        condition: condition,
        isGroupItem: isGroupItem,
        groupName: groupName,
        imagePath: imagePath,
      );
    });
    return ok ? created : null;
  }

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
    ItemModel? updated;
    final ok = await _act(() async {
      updated = await _service.updateItem(
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
    return ok ? updated : null;
  }

  Future<bool> deleteItem(int id) => _act(() => _service.deleteItem(id));

  Future<bool> _act(Future<void> Function() action) async {
    isSaving = true;
    actionError = null;
    notifyListeners();
    var success = false;
    try {
      await action();
      success = true;
    } on ApiException catch (e) {
      actionError = e.message;
    } catch (_) {
      actionError = 'Something went wrong. Please try again.';
    }
    isSaving = false;
    notifyListeners();
    if (success) {
      // refresh both lists so every screen shows the change
      await Future.wait([load(), loadMine()]);
    }
    return success;
  }

  /// Clears everything (used on logout).
  void reset() {
    items = [];
    myItems = [];
    myTotal = 0;
    search = '';
    category = null;
    condition = null;
    onlyAvailable = false;
    typeFilter = 'all';
    error = null;
    hasMore = false;
    notifyListeners();
  }
}
