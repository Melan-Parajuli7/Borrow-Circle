import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';
import 'base_viewmodel.dart';

/// ViewModel for personal task management in the profile section.
///
/// Holds the user's task list and delegates data operations to the
/// [TaskRepository]. Provides derived collections (completed / pending),
/// priority filtering, and loading/error state via [BaseViewModel].
class TaskViewModel extends BaseViewModel {
  /// Creates a [TaskViewModel] backed by [repository].
  TaskViewModel(this._repository);

  /// Repository used to perform task CRUD operations.
  final TaskRepository _repository;

  List<TaskModel> _tasks = [];
  /// All tasks for the current user.
  List<TaskModel> get tasks => _tasks;

  /// Tasks that are not yet completed.
  List<TaskModel> get pendingTasks =>
      _tasks.where((t) => !t.isCompleted).toList();

  /// Tasks that are marked as completed.
  List<TaskModel> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList();

  /// Total number of tasks.
  int get taskCount => _tasks.length;

  /// Number of completed tasks.
  int get completedCount => completedTasks.length;

  /// Number of pending tasks.
  int get pendingCount => pendingTasks.length;

  /// Tasks filtered by [priority], or all tasks if [priority] is null.
  List<TaskModel> tasksByPriority(String? priority) {
    if (priority == null) return _tasks;
    return _tasks.where((t) => t.priority == priority).toList();
  }

  /// Tasks filtered by [category], or all tasks if [category] is null.
  List<TaskModel> tasksByCategory(String? category) {
    if (category == null) return _tasks;
    return _tasks.where((t) => t.category == category).toList();
  }

  /// Fetches all tasks for the current user from local storage.
  Future<bool> loadTasks() async {
    return runWithLoading(() async {
      _tasks = await _repository.getTasks();
    });
  }

  /// Creates a new task.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> createTask({
    required String title,
    String? description,
    String? priority,
    String? category,
    String? dueDate,
  }) async {
    return runWithLoading(() async {
      final newTask = await _repository.createTask(
        title: title,
        description: description,
        priority: priority,
        category: category,
        dueDate: dueDate,
      );
      _tasks.insert(0, newTask);
    });
  }

  /// Toggles the completion status of the given [task].
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> toggleTask(TaskModel task) async {
    return runWithLoading(() async {
      final updated = await _repository.updateTask(
        id: task.id,
        isCompleted: !task.isCompleted,
      );
      _tasks = _tasks.map((t) => t.id == updated.id ? updated : t).toList();
    });
  }

  /// Updates a task's fields.
  ///
  /// Only non-null parameters are updated. Returns `true` on success.
  Future<bool> updateTask({
    required String id,
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    String? category,
    String? dueDate,
  }) async {
    return runWithLoading(() async {
      final updated = await _repository.updateTask(
        id: id,
        title: title,
        description: description,
        isCompleted: isCompleted,
        priority: priority,
        category: category,
        dueDate: dueDate,
      );
      _tasks = _tasks.map((t) => t.id == updated.id ? updated : t).toList();
    });
  }

  /// Deletes the task with the given [id].
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> deleteTask(String id) async {
    return runWithLoading(() async {
      await _repository.deleteTask(id);
      _tasks.removeWhere((t) => t.id == id);
    });
  }

  @override
  void reset() {
    super.reset();
    _tasks.clear();
  }
}
