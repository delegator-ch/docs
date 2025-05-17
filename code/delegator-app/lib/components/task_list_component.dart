// lib/components/task_list_component.dart
import 'package:flutter/material.dart';
import '../model/task_model.dart';
import '../service/task_service.dart';
import '../service/user_service.dart'; // Import UserService to get current user ID

class TaskListComponent extends StatefulWidget {
  final List<Task> tasks;
  final Function() onTasksChanged;
  final bool showProject;
  final int? projectId;
  final String title;
  final VoidCallback? onViewAllPressed;

  const TaskListComponent({
    super.key,
    required this.tasks,
    required this.onTasksChanged,
    this.showProject = true,
    this.projectId,
    required this.title,
    this.onViewAllPressed,
  });

  @override
  State<TaskListComponent> createState() => _TaskListComponentState();
}

class _TaskListComponentState extends State<TaskListComponent> {
  final TaskService _taskService = TaskService();
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.onViewAllPressed != null)
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: widget.onViewAllPressed,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        widget.tasks.isEmpty ? _buildEmptyTasksMessage() : _buildTasksList(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showAddTaskDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Task'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTasksMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Icon(Icons.task_alt, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              widget.projectId != null
                  ? 'No tasks for this project'
                  : 'No tasks available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a task to get started',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: widget.tasks.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final task = widget.tasks[index];
        return _buildTaskItem(task);
      },
    );
  }

  Widget _buildTaskItem(Task task) {
    return Dismissible(
      key: Key('task_${task.id}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Delete Task'),
              content: Text('Are you sure you want to delete "${task.title}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('DELETE'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        try {
          await _taskService.deleteTask(task.id);
          widget.onTasksChanged();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Task "${task.title}" deleted')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error deleting task: $e')));
            widget.onTasksChanged(); // Refresh to restore the task in UI
          }
        }
      },
      child: ListTile(
        leading: Checkbox(
          value: task.completed,
          onChanged:
              _isUpdating
                  ? null
                  : (bool? value) async {
                    if (value != null) {
                      setState(() => _isUpdating = true);
                      try {
                        await _taskService.toggleTaskCompletion(task);
                        widget.onTasksChanged();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error updating task: $e')),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isUpdating = false);
                        }
                      }
                    }
                  },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration:
                task.completed
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.content != null && task.content!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  task.content!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  if (task.userName != null) ...[
                    Icon(Icons.person, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      task.userName!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.showProject && task.projectName != null) ...[
                    Icon(Icons.folder, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      task.projectName!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  if (task.deadline != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(task.deadline!),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            _isOverdue(task.deadline!)
                                ? Colors.red
                                : Colors.grey[600],
                      ),
                    ),
                  ],
                  if (task.statusName != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.list_alt, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      task.statusName!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        onTap: () => _showEditTaskDialog(context, task),
      ),
    );
  }

  String _formatDate(String date) {
    final dateTime = DateTime.parse(date);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  bool _isOverdue(String date) {
    final dueDate = DateTime.parse(date);
    final today = DateTime.now();
    return dueDate.isBefore(DateTime(today.year, today.month, today.day));
  }

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final contentController =
        TextEditingController(); // Renamed from descriptionController
    DateTime? selectedDeadline; // Renamed from selectedDate

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      decoration: const InputDecoration(
                        labelText:
                            'Content (optional)', // Renamed from Description
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDeadline !=
                                    null // Renamed from selectedDate
                                ? 'Deadline: ${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}'
                                : 'No deadline set', // Renamed from due date
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDeadline =
                                    date; // Renamed from selectedDate
                              });
                            }
                          },
                          child: const Text(
                            'Set Deadline',
                          ), // Renamed from Set Due Date
                        ),
                        if (selectedDeadline !=
                            null) // Renamed from selectedDate
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                selectedDeadline =
                                    null; // Renamed from selectedDate
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Title cannot be empty')),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop();

                    try {
                      // Use the project ID from widget.projectId if available, otherwise use a default project ID (1)
                      // Note: Removed the hardcoded project ID (17)
                      final projectId = widget.projectId ?? 1;

                      // Log the task creation attempt
                      print('Attempting to create task with:');
                      print('- Title: ${titleController.text.trim()}');
                      print('- Content: ${contentController.text.trim()}');
                      print(
                        '- Deadline: ${selectedDeadline?.toIso8601String()}',
                      );
                      print('- Project: $projectId');
                      print('- User: ${UserService.currentUser?.id}');

                      await _taskService.createTask(
                        title: titleController.text.trim(),
                        status: 1,
                        content:
                            contentController.text.trim().isNotEmpty
                                ? contentController.text.trim()
                                : null,
                        deadline: selectedDeadline?.toIso8601String(),
                        project: projectId,
                        user:
                            UserService
                                .currentUser
                                ?.id, // Renamed from assignedTo to user
                      );

                      widget.onTasksChanged();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task created successfully'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        // Improved error message to include full exception details
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error creating task: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    contentController.dispose();
  }

  Future<void> _showEditTaskDialog(BuildContext context, Task task) async {
    final titleController = TextEditingController(text: task.title);
    final contentController = TextEditingController(text: task.content ?? '');
    DateTime? selectedDeadline =
        task.deadline != null ? DateTime.parse(task.deadline!) : null;

    // Track if task is completed for UI
    bool isCompleted = task.completed;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isCompleted,
                          onChanged: (bool? value) {
                            if (value != null) {
                              setState(() {
                                isCompleted = value;
                              });
                            }
                          },
                        ),
                        const Text('Completed'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      decoration: const InputDecoration(
                        labelText: 'Content (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDeadline != null
                                ? 'Deadline: ${selectedDeadline!.day}/${selectedDeadline!.month}/${selectedDeadline!.year}'
                                : 'No deadline set',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDeadline ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDeadline = date;
                              });
                            }
                          },
                          child: const Text('Set Deadline'),
                        ),
                        if (selectedDeadline != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                selectedDeadline = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Title cannot be empty')),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop();

                    try {
                      // Log the update attempt
                      print('Updating task ${task.id} with:');
                      print('- Title: ${titleController.text.trim()}');
                      print('- Content: ${contentController.text.trim()}');
                      print(
                        '- Deadline: ${selectedDeadline?.toIso8601String()}',
                      );
                      print('- Completed: $isCompleted');

                      // Create an updated task with the new values
                      final updatedTask = task.copyWith(
                        title: titleController.text.trim(),
                        content:
                            contentController.text.trim().isNotEmpty
                                ? contentController.text.trim()
                                : null,
                        deadline: selectedDeadline?.toIso8601String(),
                        // Convert the UI completed state to the appropriate status
                        status: isCompleted ? 3 : 1,
                      );

                      await _taskService.updateTask(updatedTask);
                      widget.onTasksChanged();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task updated successfully'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating task: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    contentController.dispose();
  }
}
