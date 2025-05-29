// lib/views/tasks_list_page.dart

import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/project.dart';
import 'task_detail_page.dart';
import 'create_task_dialog.dart';

class TasksListPage extends StatefulWidget {
  final int projectId;
  final String? projectName;

  const TasksListPage({
    Key? key,
    required this.projectId,
    this.projectName,
  }) : super(key: key);

  @override
  _TasksListPageState createState() => _TasksListPageState();
}

class _TasksListPageState extends State<TasksListPage> {
  List<Task> _tasks = [];
  Project? _project;
  List<User> _projectUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedStatus =
      0; // 0 = All, 1 = Backlog, 2 = In Progress, 3 = Completed
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final futures = await Future.wait([
        ServiceRegistry().taskService.getByProjectId(widget.projectId),
        ServiceRegistry().projectService.getById(widget.projectId),
        ServiceRegistry().userService.getByProjectId(widget.projectId),
      ]);

      final tasks = futures[0] as List<Task>;
      final project = futures[1] as Project;
      final users = futures[2] as List<User>;

      setState(() {
        _tasks = tasks;
        _project = project;
        _projectUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Task> get _filteredTasks {
    var filtered = _tasks;

    // Filter by status
    if (_selectedStatus > 0) {
      filtered =
          filtered.where((task) => task.status == _selectedStatus).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        final title = task.title.toLowerCase();
        final content = task.content?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || content.contains(query);
      }).toList();
    }

    return filtered;
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'All Tasks';
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

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.grey;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 4:
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName != null
            ? '${widget.projectName} Tasks'
            : 'Tasks'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatusFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(0, 'All'),
          const SizedBox(width: 8),
          _buildFilterChip(1, 'Backlog'),
          const SizedBox(width: 8),
          _buildFilterChip(2, 'In Progress'),
          const SizedBox(width: 8),
          _buildFilterChip(3, 'Completed'),
          const SizedBox(width: 8),
          _buildFilterChip(4, 'Blocked'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int status, String label) {
    final isSelected = _selectedStatus == status;
    final color = status == 0 ? Colors.purple : _getStatusColor(status);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
      },
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
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
              'Error loading tasks',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_errorMessage!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTasks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredTasks = _filteredTasks;

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.task_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No tasks found matching "$_searchQuery"'
                  : 'No ${_selectedStatus > 0 ? _getStatusText(_selectedStatus).toLowerCase() : ''} tasks yet',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Create a new task to get started',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          return TaskCard(
            task: task,
            projectUsers: _projectUsers,
            onTap: () => _openTaskDetail(task),
          );
        },
      ),
    );
  }

  Future<void> _openTaskDetail(Task task) async {
    if (task.id != null) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TaskDetailPage(
            taskId: task.id!,
            taskTitle: task.title,
          ),
        ),
      );

      if (result == true) {
        _loadTasks();
      }
    }
  }

  Future<void> _showCreateTaskDialog() async {
    final Task? newTask = await showDialog<Task>(
      context: context,
      builder: (context) => CreateTaskDialog(projectId: widget.projectId),
    );

    if (newTask != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task "${newTask.title}" created successfully!'),
        ),
      );
      _loadTasks();
    }
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final List<User> projectUsers;
  final VoidCallback onTap;

  const TaskCard({
    Key? key,
    required this.task,
    required this.projectUsers,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getStatusIcon(task.status),
                      color: _getStatusColor(task.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusChip(task.status),
                            if (task.deadline != null) ...[
                              const SizedBox(width: 8),
                              _buildDeadlineChip(task.deadline!),
                            ],
                            // Always show assignee chip (either assigned user or unassigned)
                            const SizedBox(width: 8),
                            _buildAssigneeChip(task.user),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              if (task.content != null && task.content!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  task.content!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(int status) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDeadlineChip(DateTime deadline) {
    final color = _getDeadlineColor(deadline);
    final text = _formatDeadline(deadline);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.grey;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
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

  Color _getDeadlineColor(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;

    if (difference < 0) return Colors.red;
    if (difference <= 1) return Colors.orange;
    if (difference <= 3) return Colors.yellow[700]!;
    return Colors.green;
  }

  Widget _buildAssigneeChip(int? userId) {
    if (userId == null) {
      // Show unassigned placeholder
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 8,
              backgroundColor: Colors.grey[400],
              child: Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 10,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Unassigned',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final user = projectUsers.firstWhere(
      (u) => u.id == userId,
      orElse: () => User(id: userId, username: 'Unknown User'),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 8,
            backgroundColor: Colors.purple,
            child: Text(
              user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            user.displayName,
            style: TextStyle(
              fontSize: 12,
              color: Colors.purple[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;

    if (difference < 0) return '${(-difference)} days overdue';
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference <= 7) return 'In $difference days';
    return '${deadline.day}/${deadline.month}/${deadline.year}';
  }
}
