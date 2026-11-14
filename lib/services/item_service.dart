import 'package:borrowcircle/model/item_model.dart';
import 'package:borrowcircle/model/paged.dart';
import 'package:borrowcircle/services/api_service.dart';

/// Talks to  /api/items/...
class ItemService {
  /// GET /items  (search, filters, pages)
  Future<Paged<ItemModel>> getItems({
    String? search,
    String? category,
    String? condition,
    bool? available,
    int page = 1,
    int limit = 10,
  }) async {
    final json = await ApiService.get('/items', query: {
      'search': search,
      'category': category,
      'condition': condition,
      'available': available,
      'page': page,
      'limit': limit,
    });
    return Paged<ItemModel>.fromJson(json, 'items', ItemModel.fromJson);
  }

  /// GET /items/my  (items I listed)
  Future<Paged<ItemModel>> getMyItems({int page = 1, int limit = 50}) async {
    final json = await ApiService.get('/items/my', query: {'page': page, 'limit': limit});
    return Paged<ItemModel>.fromJson(json, 'items', ItemModel.fromJson);
  }

  Future<ItemModel> getItem(int id) async {
    final json = await ApiService.get('/items/$id');
    return ItemModel.fromJson(json['item']);
  }

  /// POST /items  (multipart because of the photo)
  Future<ItemModel> createItem({
    required String title,
    String? description,
    String? category,
    String condition = 'good',
    bool isGroupItem = false,
    String? groupName,
    String? imagePath,
  }) async {
    final json = await ApiService.multipart(
      'POST',
      '/items',
      fields: _fields(title, description, category, condition, isGroupItem, groupName),
      fileField: 'image',
      filePath: imagePath,
    );
    return ItemModel.fromJson(json['item']);
  }

  /// PUT /items/:id
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
  }) async {
    final fields = _fields(title, description, category, condition, isGroupItem, groupName);
    if (isAvailable != null) fields['is_available'] = '$isAvailable';
    final json = await ApiService.multipart(
      'PUT',
      '/items/$id',
      fields: fields,
      fileField: 'image',
      filePath: imagePath,
    );
    return ItemModel.fromJson(json['item']);
  }

  Future<void> deleteItem(int id) async {
    await ApiService.delete('/items/$id');
  }

  // multipart/form-data only sends text, so bool becomes "true"/"false"
  Map<String, String> _fields(String title, String? description, String? category, String condition,
      bool isGroupItem, String? groupName) {
    return {
      'title': title.trim(),
      'description': (description ?? '').trim(),
      'category': (category ?? '').trim(),
      'condition': condition,
      'is_group_item': '$isGroupItem',
      'group_name': isGroupItem ? (groupName ?? '').trim() : '',
    };
  }
}
