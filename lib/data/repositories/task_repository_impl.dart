import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_model.dart';
import 'task_repository.dart';

/// Concrete implementation of [TaskRepository] using [SharedPreferences].
///
/// Tasks are stored as a JSON array under the key `account_tasks` and are
/// scoped to the current user. This provides offline-first task management
/// without requiring backend API endpoints.
class TaskRepositoryImpl implements TaskRepository {
  static const String _tasksKey = 'account_tasks';

  @override
  Future<List<TaskModel>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_tasksKey) ?? const <String>[];
    return raw
        .map((item) => TaskModel.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<TaskModel> createTask({
    required String title,
    String? description,
    String? priority,
    String? category,
    String? dueDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now().toIso8601String();
    final desc = (description ?? '').trim();
    String? taskDescription;
    if (desc.isNotEmpty) {
      taskDescription = desc;
    }
    final task = TaskModel(
      id: id,
      title: title.trim(),
      description: taskDescription,
      priority: priority ?? 'medium',
      category: category ?? 'Personal',
      dueDate: dueDate,
      createdAt: now,
    );

    final all = await getTasks();
    all.add(task);
    await prefs.setStringList(
      _tasksKey,
      all.map((t) => jsonEncode(t.toJson())).toList(),
    );
    return task;
  }

  @override
  Future<TaskModel> updateTask({
    required String id,
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    String? category,
    String? dueDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getTasks();
    final index = all.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw Exception('Task not found');
    }

    final updated = all[index].copyWith(
      title: title,
      description: description,
      isCompleted: isCompleted,
      priority: priority,
      category: category,
      dueDate: dueDate,
    );
    all[index] = updated;
    await prefs.setStringList(
      _tasksKey,
      all.map((t) => jsonEncode(t.toJson())).toList(),
    );
    return updated;
  }

  @override
  Future<void> deleteTask(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await getTasks();
    all.removeWhere((t) => t.id == id);
    await prefs.setStringList(
      _tasksKey,
      all.map((t) => jsonEncode(t.toJson())).toList(),
    );
  }
}
