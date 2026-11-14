import 'package:flutter/foundation.dart';

import 'package:borrowcircle/model/group_model.dart';
import 'package:borrowcircle/services/api_service.dart';
import 'package:borrowcircle/services/group_service.dart';

/// Campus groups (built from group items, see GroupService).
class GroupController extends ChangeNotifier {
  final GroupService _service = GroupService();

  List<GroupModel> groups = [];
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      groups = await _service.getGroups();
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Could not load groups.';
    }
    isLoading = false;
    notifyListeners();
  }

  /// Groups where I listed at least one item (I act as the coordinator / "Admin").
  List<GroupModel> managedBy(int userId) =>
      groups.where((g) => g.items.any((i) => i.ownerId == userId)).toList();

  List<GroupModel> othersFor(int userId) =>
      groups.where((g) => !g.items.any((i) => i.ownerId == userId)).toList();

  void reset() {
    groups = [];
    error = null;
    notifyListeners();
  }
}
