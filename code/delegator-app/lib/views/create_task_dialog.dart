// lib/views/create_task_dialog.dart

import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import '../models/task.dart';
import '../models/user.dart';

class CreateTaskDialog extends StatefulWidget {
  final int projectId;

  const CreateTaskDialog({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  _CreateTaskDialogState createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _selectedDeadline;
  User? _selectedUser;
  List<User> _projectUsers = [];
  bool _isLoading = false;
  bool _isLoadingUsers = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProjectUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectUsers() async {
    try {
      final users =
          await ServiceRegistry().userService.getByProjectId(widget.projectId);
      setState(() {
        _projectUsers = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load project users: $e';
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final task = Task(
        title: _titleController.text.trim(),
        content: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        project: widget.projectId,
        user: _selectedUser?.id,
        deadline: _selectedDeadline,
        status: 1, // Backlog
      );

      final createdTask = await ServiceRegistry().taskService.create(task);
      Navigator.of(context).pop(createdTask);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
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
    return AlertDialog(
      title: const Text('Create New Task'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'Enter task title',
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
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter task description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // User Assignment Dropdown
              if (_isLoadingUsers)
                const Center(child: CircularProgressIndicator())
              else if (_projectUsers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('No project members available'),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<User>(
                  value: _selectedUser,
                  decoration: const InputDecoration(
                    labelText: 'Assign to (Optional)',
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
                        child: Text(user.username),
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
                              'Deadline (Optional)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
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

              // Error Message
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
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createTask,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Create Task'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
