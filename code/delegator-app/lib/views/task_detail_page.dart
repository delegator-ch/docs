// lib/views/task_detail_page.dart

import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/project.dart';

class TaskDetailPage extends StatefulWidget {
  final int taskId;
  final String? taskTitle;

  const TaskDetailPage({
    Key? key,
    required this.taskId,
    this.taskTitle,
  }) : super(key: key);

  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  Task? _task;
  Project? _project;
  List<User> _projectUsers = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _errorMessage;

  User? _selectedUser;
  DateTime? _selectedDeadline;
  int _selectedStatus = 1;

  @override
  void initState() {
    super.initState();
    _loadTaskData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadTaskData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final task = await ServiceRegistry().taskService.getById(widget.taskId);
      final project =
          await ServiceRegistry().projectService.getById(task.project);
      final users =
          await ServiceRegistry().userService.getByProjectId(task.project);

      setState(() {
        _task = task;
        _project = project;
        _projectUsers = users;

        // Populate form fields
        _titleController.text = task.title;
        _contentController.text = task.content ?? '';
        _selectedStatus = task.status;
        _selectedDeadline = task.deadline;
        _selectedUser = task.user != null
            ? users.firstWhere((u) => u.id == task.user,
                orElse: () => users.first)
            : null;

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updatedTask = Task(
        id: _task!.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim().isNotEmpty
            ? _contentController.text.trim()
            : null,
        project: _task!.project,
        user: _selectedUser?.id,
        deadline: _selectedDeadline,
        status: _selectedStatus,
        duration: _task!.duration,
        created: _task!.created,
        updated: DateTime.now(),
        dependentOnTaskId: _task!.dependentOnTaskId,
        event: _task!.event,
      );

      await ServiceRegistry().taskService.update(updatedTask);

      setState(() {
        _task = updatedTask;
        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task updated successfully')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSaving = false;
      });
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${_task!.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ServiceRegistry().taskService.delete(widget.taskId);
        Navigator.of(context).pop(true); // Return true to indicate deletion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select task deadline',
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskTitle ?? 'Task Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _task != null) ...[
            if (_isEditing) ...[
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _isSaving ? null : _saveTask,
              ),
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    // Reset form fields
                    _titleController.text = _task!.title;
                    _contentController.text = _task!.content ?? '';
                    _selectedStatus = _task!.status;
                    _selectedDeadline = _task!.deadline;
                    _selectedUser = _task!.user != null
                        ? _projectUsers.firstWhere((u) => u.id == _task!.user,
                            orElse: () => _projectUsers.first)
                        : null;
                  });
                },
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => _isEditing = true),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'delete':
                      _deleteTask();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete Task',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading task',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_errorMessage!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTaskData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskHeader(),
            const SizedBox(height: 20),
            if (_isEditing) ...[
              _buildEditForm(),
            ] else ...[
              _buildViewMode(),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader() {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [Colors.blue[400]!, Colors.blue[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStatusIcon(_task!.status),
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _task!.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${_getStatusText(_task!.status)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_project != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.work, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Project: ${_project!.name ?? 'Unknown'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(),
        const SizedBox(height: 20),
        _buildMetadataCard(),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task Title
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Task Title *',
            prefixIcon: Icon(Icons.task),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a task title';
            }
            return null;
          },
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),

        // Task Description
        TextFormField(
          controller: _contentController,
          decoration: const InputDecoration(
            labelText: 'Description',
            prefixIcon: Icon(Icons.description),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),

        // Status Dropdown
        DropdownButtonFormField<int>(
          value: _selectedStatus,
          decoration: const InputDecoration(
            labelText: 'Status',
            prefixIcon: Icon(Icons.timeline),
          ),
          items: const [
            DropdownMenuItem(value: 1, child: Text('🔴 Backlog')),
            DropdownMenuItem(value: 2, child: Text('🟡 In Progress')),
            DropdownMenuItem(value: 3, child: Text('🟢 Completed')),
            DropdownMenuItem(value: 4, child: Text('🔴 Blocked')),
          ],
          onChanged: (int? newValue) {
            setState(() {
              _selectedStatus = newValue ?? 1;
            });
          },
        ),
        const SizedBox(height: 16),

        // User Assignment
        if (_projectUsers.isNotEmpty) ...[
          DropdownButtonFormField<User>(
            value: _selectedUser,
            decoration: const InputDecoration(
              labelText: 'Assigned to',
              prefixIcon: Icon(Icons.person),
            ),
            items: [
              const DropdownMenuItem<User>(
                value: null,
                child: Text('Unassigned'),
              ),
              ..._projectUsers.map((user) {
                return DropdownMenuItem<User>(
                  value: user,
                  child: Text(user.displayName),
                );
              }).toList(),
            ],
            onChanged: (User? newValue) {
              setState(() {
                _selectedUser = newValue;
              });
            },
          ),
          const SizedBox(height: 16),
        ],

        // Deadline Selection
        InkWell(
          onTap: _selectDeadline,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Deadline',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _selectedDeadline != null
                            ? _formatDate(_selectedDeadline!)
                            : 'No deadline set',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                if (_selectedDeadline != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedDeadline = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Save Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Save Changes'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_task!.content != null && _task!.content!.isNotEmpty) ...[
              const Text(
                'Description',
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(_task!.content!),
              const SizedBox(height: 12),
            ],
            _buildDetailRow('Status', _getStatusText(_task!.status)),
            if (_selectedUser != null)
              _buildDetailRow('Assigned to', _selectedUser!.displayName),
            if (_task!.deadline != null)
              _buildDetailRow('Deadline', _formatDate(_task!.deadline!)),
            _buildDetailRow('Duration', '${_task!.duration} hours'),
            if (_task!.dependentOnTaskId != null)
              _buildDetailRow(
                  'Depends on', 'Task #${_task!.dependentOnTaskId}'),
            if (_task!.event != null)
              _buildDetailRow('Related event', 'Event #${_task!.event}'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metadata',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Task ID', _task!.id?.toString() ?? 'Unknown'),
            _buildDetailRow('Project ID', _task!.project.toString()),
            if (_task!.created != null)
              _buildDetailRow('Created', _formatDateTime(_task!.created!)),
            if (_task!.updated != null)
              _buildDetailRow('Updated', _formatDateTime(_task!.updated!)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'Backlog';
      case 2:
        return 'In Progress';
      case 3:
        return 'Completed';
      case 4:
        return 'Blocked';
      default:
        return 'Unknown';
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.inbox;
      case 2:
        return Icons.play_arrow;
      case 3:
        return Icons.check_circle;
      case 4:
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
