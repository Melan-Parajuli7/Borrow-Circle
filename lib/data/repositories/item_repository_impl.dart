import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../data/models/item_model.dart';
import '../../data/models/paged.dart';
import 'item_repository.dart';

/// Concrete implementation of [ItemRepository] backed by the Express API.
class ItemRepositoryImpl implements ItemRepository {
  /// API client used to make authenticated HTTP requests.
  final ApiClient _apiClient;

  /// Creates an [ItemRepositoryImpl] with the given [apiClient].
  ItemRepositoryImpl(this._apiClient);

  @override
  Future<Paged<ItemModel>> getItems({
    String? search,
    String? category,
    String? condition,
    bool? available,
    int page = 1,
    int limit = 10,
  }) async {
    final json = await _apiClient.get(AppConstants.itemsEndpoint, query: {
      'search': search,
      'category': category,
      'condition': condition,
      'available': available,
      'page': page,
      'limit': limit,
    });
    return Paged<ItemModel>.fromJson(json, 'items', ItemModel.fromJson);
  }

  @override
  Future<Paged<ItemModel>> getMyItems({int page = 1, int limit = 50}) async {
    final json = await _apiClient
        .get(AppConstants.myItemsEndpoint, query: {'page': page, 'limit': limit});
    return Paged<ItemModel>.fromJson(json, 'items', ItemModel.fromJson);
  }

  @override
  Future<ItemModel> getItem(int id) async {
    final json = await _apiClient.get('${AppConstants.itemsEndpoint}/$id');
    return ItemModel.fromJson(json['item']);
  }

  @override
  Future<ItemModel> createItem({
    required String title,
    String? description,
    String? category,
    String condition = 'good',
    bool isGroupItem = false,
    String? groupName,
    String? imagePath,
  }) async {
    final json = await _apiClient.multipart(
      'POST',
      AppConstants.itemsEndpoint,
      fields: _fields(title, description, category, condition, isGroupItem, groupName),
      fileField: 'image',
      filePath: imagePath,
    );
    return ItemModel.fromJson(json['item']);
  }

  @override
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
    final json = await _apiClient.multipart(
      'PUT',
      '${AppConstants.itemsEndpoint}/$id',
      fields: fields,
      fileField: 'image',
      filePath: imagePath,
    );
    return ItemModel.fromJson(json['item']);
  }

  @override
  Future<void> deleteItem(int id) async {
    await _apiClient.delete('${AppConstants.itemsEndpoint}/$id');
  }

  Map<String, String> _fields(
    String title,
    String? description,
    String? category,
    String condition,
    bool isGroupItem,
    String? groupName,
  ) {
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