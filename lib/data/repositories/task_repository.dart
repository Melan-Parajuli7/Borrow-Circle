import '../models/task_model.dart';

/// Abstract contract for task data access.
///
/// The ViewModel depends on this interface so the data source can be swapped
/// (e.g. mocked for tests) without touching the presentation layer.
abstract class TaskRepository {
  /// Fetches all tasks belonging to the current user.
  ///
  /// Returns a list of [TaskModel] objects. Throws an exception on failure.
  Future<List<TaskModel>> getTasks();

  /// Creates a new task with the given [title], [description], [priority],
  /// [category], and optional [dueDate].
  ///
  /// Returns the newly created [TaskModel] as persisted locally.
  Future<TaskModel> createTask({
    required String title,
    String? description,
    String? priority,
    String? category,
    String? dueDate,
  });

  /// Partially updates an existing task identified by [id].
  ///
  /// Only non-null parameters are sent to the store, allowing partial updates
  /// such as toggling only `isCompleted`. Returns the updated [TaskModel].
  Future<TaskModel> updateTask({
    required String id,
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    String? category,
    String? dueDate,
  });

  /// Deletes the task with the given [id].
  ///
  /// Throws an exception if the task does not exist or the operation fails.
  Future<void> deleteTask(String id);
}
