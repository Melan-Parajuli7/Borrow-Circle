import '../../data/models/item_model.dart';
import '../../data/models/paged.dart';

/// Abstract contract for item data access.
abstract class ItemRepository {
  /// Fetches a paginated list of items with optional filters.
  Future<Paged<ItemModel>> getItems({
    String? search,
    String? category,
    String? condition,
    bool? available,
    int page = 1,
    int limit = 10,
  });

  /// Fetches a paginated list of items owned by the current user.
  Future<Paged<ItemModel>> getMyItems({int page = 1, int limit = 50});

  /// Fetches a single item by ID.
  Future<ItemModel> getItem(int id);

  /// Creates a new item.
  Future<ItemModel> createItem({
    required String title,
    String? description,
    String? category,
    String condition = 'good',
    bool isGroupItem = false,
    String? groupName,
    String? imagePath,
  });

  /// Updates an existing item.
  Future<ItemModel> updateItem(
    int id, {
    required String title,
    String? description,
    String? category,
    required String condition,
    required bool isGroupItem,
    String? groupName,
    bool? isAvailable,
    String? imagePath,
  });

  /// Deletes an item.
  Future<void> deleteItem(int id);
}