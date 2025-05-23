// lib/views/project_detail_page.dart

import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/chat.dart';

class ProjectDetailPage extends StatefulWidget {
  final int projectId;
  final String? projectName;

  const ProjectDetailPage({Key? key, required this.projectId, this.projectName})
      : super(key: key);

  @override
  _ProjectDetailPageState createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage>
    with SingleTickerProviderStateMixin {
  Project? _project;
  List<Task> _tasks = [];
  List<Chat> _chats = [];
  bool _isLoading = true;
  String? _errorMessage;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProjectData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load project details and related data
      final futures = await Future.wait([
        ServiceRegistry().projectService.getById(widget.projectId),
        ServiceRegistry().taskService.getByProjectId(widget.projectId),
        ServiceRegistry().chatService.getByProjectId(widget.projectId),
      ]);

      final project = futures[0] as Project;
      final tasks = futures[1] as List<Task>;
      final chats = futures[2] as List<Chat>;

      setState(() {
        _project = project;
        _tasks = tasks;
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName ?? 'Project Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProjectData,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editProject();
                  break;
                case 'share':
                  _shareProject();
                  break;
                case 'archive':
                  _archiveProject();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('Edit Project'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('Share Project'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(Icons.archive, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Archive Project'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: _isLoading
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Overview', icon: Icon(Icons.info)),
                  Tab(text: 'Tasks', icon: Icon(Icons.task)),
                  Tab(text: 'Chats', icon: Icon(Icons.chat)),
                ],
              ),
      ),
      body: _buildBody(),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton(
              onPressed: _showAddOptions,
              backgroundColor: Colors.green,
              child: const Icon(Icons.add, color: Colors.white),
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
              'Error loading project',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_errorMessage!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProjectData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [_buildOverviewTab(), _buildTasksTab(), _buildChatsTab()],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProjectHeader(),
          const SizedBox(height: 20),
          _buildProjectStats(),
          const SizedBox(height: 20),
          _buildProjectDetails(),
          const SizedBox(height: 20),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildProjectHeader() {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [Colors.green[400]!, Colors.green[600]!],
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
                  child: const Icon(Icons.work, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _project?.name ?? 'Unknown Project',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Priority: ${_getPriorityText(_project?.priority ?? 0)}',
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
            if (_project?.deadline != null) ...[
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
                    const Icon(Icons.schedule, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Due: ${_formatDate(_project!.deadline!)}',
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

  Widget _buildProjectStats() {
    final completedTasks = _tasks
        .where((task) => task.status == 3)
        .length; // Assuming status 3 is completed
    final totalTasks = _tasks.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Tasks',
            totalTasks.toString(),
            Icons.task,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Completed',
            completedTasks.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Chats',
            _chats.length.toString(),
            Icons.chat,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Project ID',
              _project?.id?.toString() ?? 'Unknown',
            ),
            _buildDetailRow(
              'Organization',
              _project?.organisationId.toString() ?? 'Unknown',
            ),
            _buildDetailRow(
              'Priority',
              _getPriorityText(_project?.priority ?? 0),
            ),
            if (_project?.deadline != null)
              _buildDetailRow('Deadline', _formatDate(_project!.deadline!)),
            if (_project?.event != null)
              _buildDetailRow('Event ID', _project!.event.toString()),
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

  Widget _buildRecentActivity() {
    // Show recent tasks or activity
    final recentTasks = _tasks.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (recentTasks.isEmpty)
              const Text('No recent activity')
            else
              ...recentTasks.map((task) => _buildActivityItem(task)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Task task) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.green[100],
        child: Icon(Icons.task, size: 16, color: Colors.green[700]),
      ),
      title: Text(task.title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        'Status: ${task.status}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        task.created != null ? _formatTime(task.created!) : '',
        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildTasksTab() {
    return RefreshIndicator(
      onRefresh: _loadProjectData,
      child: _tasks.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tasks yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add some tasks to get started!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return _buildTaskCard(task);
              },
            ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTaskStatusColor(task.status),
          child: Icon(
            _getTaskStatusIcon(task.status),
            color: Colors.white,
            size: 16,
          ),
        ),
        title: Text(task.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.content != null && task.content!.isNotEmpty)
              Text(task.content!, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (task.deadline != null)
              Text(
                'Due: ${_formatDate(task.deadline!)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            // TODO: Handle task actions
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$value task: ${task.title}')),
            );
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(
              value: 'complete',
              child: Text('Mark Complete'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () {
          // TODO: Navigate to task detail
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Open task: ${task.title}')));
        },
      ),
    );
  }

  Widget _buildChatsTab() {
    return RefreshIndicator(
      onRefresh: _loadProjectData,
      child: _chats.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create a chat to collaborate!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _chats.length,
              itemBuilder: (context, index) {
                final chat = _chats[index];
                return _buildChatCard(chat);
              },
            ),
    );
  }

  Widget _buildChatCard(Chat chat) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.chat, color: Colors.blue[700]),
        ),
        title: Text(chat.name),
        subtitle: Text('Type: ${chat.chatType}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Navigate to chat
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Open chat: ${chat.name}')));
        },
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.task, color: Colors.blue),
              title: const Text('Add Task'),
              onTap: () {
                Navigator.pop(context);
                _addTask();
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text('Create Chat'),
              onTap: () {
                Navigator.pop(context);
                _createChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.orange),
              title: const Text('Add Member'),
              onTap: () {
                Navigator.pop(context);
                _addMember();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editProject() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Edit project coming soon!')));
  }

  void _shareProject() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share project coming soon!')));
  }

  void _archiveProject() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Archive project coming soon!')),
    );
  }

  void _addTask() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Add task coming soon!')));
  }

  void _createChat() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Create chat coming soon!')));
  }

  void _addMember() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Add member coming soon!')));
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return 'URGENT';
      case 2:
        return 'HIGH';
      case 3:
        return 'MEDIUM';
      case 4:
        return 'LOW';
      case 5:
        return 'LOWEST';
      default:
        return 'NONE';
    }
  }

  Color _getTaskStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.grey; // Backlog
      case 2:
        return Colors.blue; // In Progress
      case 3:
        return Colors.green; // Completed
      case 4:
        return Colors.red; // Blocked
      default:
        return Colors.grey;
    }
  }

  IconData _getTaskStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.inbox;
      case 2:
        return Icons.play_arrow;
      case 3:
        return Icons.check;
      case 4:
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}
