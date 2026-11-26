import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/task_model.dart';
import '../../core/constants/colors.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/app_widgets.dart';
import '../utils/validators.dart';

/// My Tasks screen - dedicated task management page.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _showAddForm = false;
  String _filterStatus = 'all';
  String _filterPriority = 'all';
  String _filterCategory = 'all';

  /// Priorities derived dynamically from available tasks.
  List<String> get _dynamicPriorities {
    final tasks = context.read<TaskViewModel>().tasks;
    final seen = <String>{};
    for (final t in tasks) {
      if (t.priority.isNotEmpty && !seen.contains(t.priority)) {
        seen.add(t.priority);
      }
    }
    return seen.toList();
  }

  /// Categories derived dynamically from available tasks.
  List<String> get _dynamicCategories {
    final tasks = context.read<TaskViewModel>().tasks;
    final seen = <String>{};
    for (final t in tasks) {
      if (t.category.isNotEmpty && !seen.contains(t.category)) {
        seen.add(t.category);
      }
    }
    return seen.toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<TaskViewModel>().loadTasks();
    });
  }

  List<TaskModel> get _filteredTasks {
    final vm = context.read<TaskViewModel>();
    var list = vm.tasks;
    if (_filterStatus == 'completed') {
      list = list.where((t) => t.isCompleted).toList();
    } else if (_filterStatus == 'pending') {
      list = list.where((t) => !t.isCompleted).toList();
    }
    if (_filterPriority != 'all') {
      list = list.where((t) => t.priority == _filterPriority).toList();
    }
    if (_filterCategory != 'all') {
      list = list.where((t) => t.category == _filterCategory).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final taskViewModel = context.watch<TaskViewModel>();
    final filteredTasks = _filteredTasks;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: const ScreenHeader(title: 'My Tasks'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<TaskViewModel>().loadTasks(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: AppColors.primaryLight,
                      child: Row(
                children: [
                  Expanded(
                    child: _TaskStatFilter(
                      value: '${taskViewModel.taskCount}',
                      label: 'Total',
                      selected: _filterStatus == 'all',
                      activeColor: AppColors.primary,
                      onSelected: () => setState(() => _filterStatus = 'all'),
                    ),
                  ),
                  Expanded(
                    child: _TaskStatFilter(
                      value: '${taskViewModel.completedCount}',
                      label: 'Completed',
                      selected: _filterStatus == 'completed',
                      activeColor: AppColors.secondary,
                      onSelected: () =>
                          setState(() => _filterStatus = 'completed'),
                    ),
                  ),
                  Expanded(
                    child: _TaskStatFilter(
                      value: '${taskViewModel.pendingCount}',
                      label: 'Pending',
                      selected: _filterStatus == 'pending',
                      activeColor: AppColors.tertiary,
                      onSelected: () =>
                          setState(() => _filterStatus = 'pending'),
                    ),
                  ),
                ],
              ),
            ),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const SizedBox(height: 8),
                  if (_showAddForm)
                    const _AddTaskFormWidget()
                  else
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextButton.icon(
                          icon: const Icon(Icons.add, color: AppColors.primary),
                          label: const Text(
                            'Add Task',
                            style: TextStyle(color: AppColors.primary),
                          ),
                          onPressed: () => setState(() => _showAddForm = true),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SegmentedTabs(
                          labels: const ['All', 'Completed', 'Pending'],
                          selected: {'all': 0, 'completed': 1, 'pending': 2}[
                              _filterStatus] ?? 0,
                          onChanged: (i) => setState(() =>
                              _filterStatus = ['all', 'completed', 'pending'][i]),
                        ),
                        const SizedBox(height: 10),
                        if (_dynamicPriorities.isNotEmpty)
                          SegmentedTabs(
                            labels: ['All',
                              ..._dynamicPriorities.map((p) =>
                                  p[0].toUpperCase() + p.substring(1))],
                            selected: _filterPriority == 'all'
                                ? 0
                                : 1 + _dynamicPriorities.indexOf(
                                    _filterPriority),
                            onChanged: (i) => setState(() =>
                                _filterPriority = i == 0
                                    ? 'all'
                                    : _dynamicPriorities[i - 1]),
                          ),
                        const SizedBox(height: 10),
                        if (_dynamicCategories.isNotEmpty)
                          SegmentedTabs(
                            labels: ['All', ..._dynamicCategories],
                            selected: _filterCategory == 'all'
                                ? 0
                                : 1 + _dynamicCategories.indexOf(
                                    _filterCategory),
                            onChanged: (i) => setState(() =>
                                _filterCategory = i == 0
                                    ? 'all'
                                    : _dynamicCategories[i - 1]),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filteredTasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          taskViewModel.tasks.isEmpty
                              ? 'No tasks yet. Add one above!'
                              : 'No tasks match the selected filters.',
                          style: const TextStyle(color: AppColors.textGrey),
                        ),
                      ),
                    )
                  else
                    ...filteredTasks.map(
                      (task) => _TaskCard(
                        task: task,
                        onToggle: () => taskViewModel.toggleTask(task),
                        onEdit: () => _showEditTaskDialog(context, task),
                        onDelete: () => taskViewModel.deleteTask(task.id),
                      ),
                    ),
                ],
              ),
            ],
            ),
            ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _showAddForm = !_showAddForm),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Status summary chip that filters the task list.
class _TaskStatFilter extends StatelessWidget {
  final String value;
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onSelected;

  const _TaskStatFilter({
    required this.value,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        selected: selected,
        showCheckmark: false,
        selectedColor: Colors.white,
        backgroundColor: AppColors.primaryLight,
        side: BorderSide(color: selected ? activeColor : AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: (_) => onSelected(),
        label: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: selected ? activeColor : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? activeColor : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Add task form widget.
class _AddTaskFormWidget extends StatefulWidget {
  const _AddTaskFormWidget();

  @override
  State<_AddTaskFormWidget> createState() => _AddTaskFormWidgetState();
}

class _AddTaskFormWidgetState extends State<_AddTaskFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedPriority = 'medium';
  String _selectedCategory = 'Personal';
  String? _dueDate;

  static const _priorities = ['low', 'medium', 'high'];
  static const _categories = ['Personal', 'Study', 'Work', 'Health', 'Finance'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final viewModel = context.read<TaskViewModel>();
    final success = await viewModel.createTask(
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      priority: _selectedPriority,
      category: _selectedCategory,
      dueDate: _dueDate,
    );
    if (!mounted) return;
    if (success) {
      _titleController.clear();
      _descController.clear();
      setState(() {
        _selectedPriority = 'medium';
        _selectedCategory = 'Personal';
        _dueDate = null;
      });
    } else {
      showSnack(
        context,
        viewModel.error ?? 'Failed to create task',
        isError: true,
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = picked.toIso8601String());
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.error;
      case 'low':
        return AppColors.secondary;
      default:
        return AppColors.tertiary;
    }
  }

  String _formatDueDate(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Task',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'What do you need to do?',
                validator: Validators.itemTitle,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _descController,
                label: 'Description',
                hint: 'Add details (optional)',
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Priority',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _priorities.map((p) {
                            final selected = _selectedPriority == p;
                            return ChoiceChip(
                              label: Text(p[0].toUpperCase() + p.substring(1)),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _selectedPriority = p),
                              selectedColor: _getPriorityColor(p)
                                  .withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                color: selected
                                    ? _getPriorityColor(p)
                                    : AppColors.textGrey,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _categories.map((c) {
                            final selected = _selectedCategory == c;
                            return ChoiceChip(
                              label: Text(c),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _selectedCategory = c),
                              selectedColor: selected
                                  ? AppColors.primaryLight
                                  : null,
                              labelStyle: TextStyle(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textGrey,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _dueDate == null
                            ? 'Due date'
                            : 'Due ${_formatDueDate(_dueDate!)}',
                      ),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(text: 'Add Task', onPressed: _submit),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Task card widget.
class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(task.id),
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (_) => onToggle(),
            activeColor: task.priorityColor,
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? AppColors.textGrey : AppColors.textDark,
            ),
          ),
          subtitle:
              task.description != null && task.description!.trim().isNotEmpty
              ? Text(
                  task.description!,
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                )
              : null,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: task.priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.priority[0].toUpperCase() + task.priority.substring(1),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: task.priorityColor,
                  ),
                ),
              ),
              if (task.dueDate != null) ...[
                const SizedBox(height: 6),
                Icon(Icons.calendar_today, size: 16, color: AppColors.textGrey),
                const SizedBox(height: 2),
                Text(
                  _formatDueDate(task.dueDate!),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ],
          ),
          onTap: onEdit,
        ),
      ),
    );
  }

  String _formatDueDate(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

/// Shows a dialog to edit the given [task].
void _showEditTaskDialog(BuildContext context, TaskModel task) {
  final tCtrl = TextEditingController(text: task.title);
  final dCtrl = TextEditingController(text: task.description);
  String selectedPriority = task.priority;
  String selectedCategory = task.category;

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Edit Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: tCtrl,
            label: 'Title',
            validator: Validators.itemTitle,
          ),
          const SizedBox(height: 16),
          AppTextField(controller: dCtrl, label: 'Description', maxLines: 2),
          const SizedBox(height: 16),
          const Text(
            'Priority',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['low', 'medium', 'high'].map((p) {
              final selected = selectedPriority == p;
              return ChoiceChip(
                label: Text(p[0].toUpperCase() + p.substring(1)),
                selected: selected,
                onSelected: (_) => selectedPriority = p,
                selectedColor: _getPriorityColor(p).withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: selected ? _getPriorityColor(p) : AppColors.textGrey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Personal', 'Study', 'Work', 'Health', 'Finance'].map((
              c,
            ) {
              final selected = selectedCategory == c;
              return ChoiceChip(
                label: Text(c),
                selected: selected,
                onSelected: (_) => selectedCategory = c,
                selectedColor: selected ? AppColors.primaryLight : null,
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textGrey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (tCtrl.text.trim().isEmpty) return;
            final viewModel = context.read<TaskViewModel>();
            final success = await viewModel.updateTask(
              id: task.id,
              title: tCtrl.text.trim(),
              description: dCtrl.text.trim().isEmpty ? null : dCtrl.text.trim(),
              priority: selectedPriority,
              category: selectedCategory,
            );
            if (!dialogContext.mounted) return;
            if (success) {
              Navigator.pop(dialogContext);
            } else {
              showSnack(
                dialogContext,
                viewModel.error ?? 'Failed to update task',
                isError: true,
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

Color _getPriorityColor(String priority) {
  switch (priority) {
    case 'high':
      return AppColors.error;
    case 'low':
      return AppColors.secondary;
    default:
      return AppColors.tertiary;
  }
}
