import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// Task model for personal task management in the profile section.
///
/// Tasks are stored locally via [SharedPreferences] and belong to the
/// authenticated user. Supports priority, due date, category, and completion
/// tracking — a smart, dynamic to-do list integrated into the user's profile.
class TaskModel {
  /// Unique identifier of the task.
  final String id;

  /// Short title of the task.
  final String title;

  /// Optional longer description.
  final String? description;

  /// Whether the task is completed.
  final bool isCompleted;

  /// Priority level: 'low', 'medium', or 'high'.
  final String priority;

  /// Category label (e.g., 'Study', 'Personal', 'Work').
  final String category;

  /// Due date as ISO-8601 string, or null if not set.
  final String? dueDate;

  /// ISO-8601 timestamp when the task was created.
  final String createdAt;

  /// Creates a [TaskModel] with all required fields.
  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.priority = 'medium',
    this.category = 'Personal',
    this.dueDate,
    required this.createdAt,
  });

  /// Creates a [TaskModel] from a JSON map.
  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        isCompleted: json['isCompleted'] as bool? ?? false,
        priority: json['priority'] as String? ?? 'medium',
        category: json['category'] as String? ?? 'Personal',
        dueDate: json['dueDate'] as String?,
        createdAt: json['createdAt'] as String,
      );

  /// Converts this [TaskModel] into a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'priority': priority,
        'category': category,
        'dueDate': dueDate,
        'createdAt': createdAt,
      };

  /// Returns a copy of this [TaskModel] with the given fields replaced.
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    String? priority,
    String? category,
    String? dueDate,
    String? createdAt,
  }) =>
      TaskModel(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        isCompleted: isCompleted ?? this.isCompleted,
        priority: priority ?? this.priority,
        category: category ?? this.category,
        dueDate: dueDate ?? this.dueDate,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Color associated with the task's priority.
  Color get priorityColor {
    switch (priority) {
      case 'high':
        return AppColors.error;
      case 'low':
        return AppColors.secondary;
      default:
        return AppColors.tertiary;
    }
  }
}
