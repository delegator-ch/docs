// lib/views/project_detail_page.dart (Updated with edit functionality and removed share/archive)

import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/chat.dart';
import '../models/user.dart';
import 'chat_detail_page.dart';
import 'create_task_dialog.dart';
import 'manage_project_users_dialog.dart';
import 'task_detail_page.dart';
import 'edit_project_dialog.dart';
import 'tasks_list_page.dart'; // Add this import

class ProjectDetailPage extends StatefulWidget {
  final int projectId;
  final int chatId;
  final String? projectName;

  const ProjectDetailPage({
    Key? key,
    required this.projectId,
    required this.chatId,
    this.projectName,
  }) : super(key: key);

  @override
  _ProjectDetailPageState createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  Project? _project;
  List<Task> _tasks = [];
  Chat? _chat;
  List<User> _projectMembers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProjectData();
  }

  @override
  void dispose() {
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
        ServiceRegistry().chatService.getById(widget.chatId),
        ServiceRegistry()
            .userService
            .getByProjectId(widget.projectId), // Load project members
      ]);

      final project = futures[0] as Project;
      final tasks = futures[1] as List<Task>;
      final chat = futures[2] as Chat;
      final members = futures[3] as List<User>;

      setState(() {
        _project = project;
        _tasks = tasks;
        _chat = chat;
        _projectMembers = members;
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
          if (_chat != null && !_isLoading)
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () => _openProjectChat(),
              tooltip: 'Open Project Chat',
            ),
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
                case 'manage_users':
                  _manageUsers();
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
                value: 'manage_users',
                child: Row(
                  children: [
                    Icon(Icons.people, color: Colors.blue),
                    SizedBox(width: 12),
                    Text('Manage Members'),
                  ],
                ),
              ),
            ],
          ),
        ],
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
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProjectHeader(),
          const SizedBox(height: 20),
          _buildProjectStats(),
          const SizedBox(height: 20),
          _buildMembersSection(), // New members section
          const SizedBox(height: 20),
          _buildProjectDetails(),
          const SizedBox(height: 20),
          _buildTasksSection(),
          const SizedBox(height: 20),
          _buildChatsSection(),
          const SizedBox(height: 20),
          _buildRecentActivity(),
          const SizedBox(height: 20),
          _buildStatusChangeSection(),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Project Members (${_projectMembers.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _manageUsers,
                  icon: const Icon(Icons.manage_accounts, size: 16),
                  label: const Text('Manage'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_projectMembers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.person_off, color: Colors.grey[400], size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'No members assigned',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add members to collaborate on this project',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _projectMembers
                    .take(5) // Show first 5 members
                    .map((member) => _buildMemberTile(member))
                    .toList(),
              ),
            if (_projectMembers.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _manageUsers,
                  child: Text('View all ${_projectMembers.length} members'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(User member) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            member.username.isNotEmpty ? member.username[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ),
        title: Text(
          member.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (member.email != null)
              Text(
                member.email!,
                style: const TextStyle(fontSize: 12),
              ),
            if (member.role != null)
              Text(
                '${member.role!.name} (Level ${member.role!.level})',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (member.accessType != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: member.accessType == 'organization'
                      ? Colors.blue[50]
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  member.accessType!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: member.accessType == 'organization'
                        ? Colors.blue[700]
                        : Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () => _showMemberDetails(member),
      ),
    );
  }

  Widget _buildProjectStats() {
    final completedTasks = _tasks
        .where((task) => task.status == 3)
        .length; // Assuming status 3 is completed
    final totalTasks = _tasks.length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

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
            'Members',
            _projectMembers.length.toString(),
            Icons.people,
            Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Chat',
            _chat != null ? '1' : '0',
            Icons.chat,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectHeader() {
    return Card(
        child: InkWell(
      onTap: _editProject,
      borderRadius: BorderRadius.circular(8),
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
                  child: const Icon(
                    Icons.work,
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
    ));
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: InkWell(
        onTap: title == 'Total Tasks'
            ? _navigateToTasksList
            : (title == 'Chat'
                ? _openProjectChat
                : (title == 'Members' ? _manageUsers : null)),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                'Project ID', _project?.id?.toString() ?? 'Unknown'),
            _buildDetailRow('Organization',
                _project?.organisationId?.toString() ?? 'Unknown'),
            _buildDetailRow(
                'Priority', _getPriorityText(_project?.priority ?? 0)),
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

  Widget _buildTasksSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _navigateToTasksList,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Icon(Icons.task, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tasks (${_tasks.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_tasks.isEmpty)
              const Text('No tasks yet')
            else
              ..._tasks.take(5).map((task) => _buildTaskCard(task)).toList(),
            if (_tasks.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Show all tasks
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Show all tasks coming soon!')),
                    );
                  },
                  child: Text('View all ${_tasks.length} tasks'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.chat, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Project Chat',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_chat == null)
              const Text('No chat available')
            else
              _buildChatCard(_chat!),
          ],
        ),
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
      subtitle:
          Text('Status: ${task.status}', style: const TextStyle(fontSize: 12)),
      trailing: Text(
        task.created != null ? _formatTime(task.created!) : '',
        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: _getTaskStatusColor(task.status),
          child: Icon(
            _getTaskStatusIcon(task.status),
            color: Colors.white,
            size: 16,
          ),
        ),
        title: Text(task.title, style: const TextStyle(fontSize: 14)),
        subtitle: task.deadline != null
            ? Text('Due: ${_formatDate(task.deadline!)}',
                style: const TextStyle(fontSize: 12))
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _openTaskEdit(task),
      ),
    );
  }

  Future<void> _openTaskEdit(Task task) async {
    if (task.id != null) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TaskDetailPage(
            taskId: task.id!,
            taskTitle: task.title,
          ),
        ),
      );

      // If task was deleted or modified, refresh the project data
      if (result == true) {
        _loadProjectData();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task ID not available')),
      );
    }
  }

  Widget _buildChatCard(Chat chat) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.blue[100],
          child: Icon(Icons.chat, color: Colors.blue[700], size: 16),
        ),
        title: Text(chat.name, style: const TextStyle(fontSize: 14)),
        subtitle: Text('Type: ${chat.chatType}',
            style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatDetailPage(
                chatId: chat.id!,
                chatName: chat.name,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChangeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Project Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatusChangeButton(1, 'Backlog', Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusChangeButton(2, 'Active', Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusChangeButton(3, 'Completed', Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChangeButton(int status, String text, Color color) {
    final isCurrentStatus = _project?.status == status;

    return ElevatedButton(
      onPressed: isCurrentStatus ? null : () => _changeProjectStatus(status),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrentStatus ? Colors.grey[300] : color,
        foregroundColor: isCurrentStatus ? Colors.grey[600] : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _changeProjectStatus(int newStatus) async {
    if (_project == null) return;

    try {
      final updatedProject = Project(
        id: _project!.id,
        name: _project!.name,
        organisationId: _project!.organisationId,
        priority: _project!.priority,
        deadline: _project!.deadline,
        status: newStatus,
        event: _project!.event,
        chat: _project!.chat,
      );

      await ServiceRegistry().projectService.update(updatedProject);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project status updated successfully')),
      );

      _loadProjectData(); // Refresh the project data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openProjectChat() {
    // Use widget.chatId directly since it's passed from the constructor
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          chatId: widget.chatId,
          chatName: _chat?.name ?? 'Project Chat',
        ),
      ),
    );
  }

  Future<void> _editProject() async {
    if (_project == null) return;

    final Project? updatedProject = await showDialog<Project>(
      context: context,
      builder: (context) => EditProjectDialog(project: _project!),
    );

    if (updatedProject != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Project "${updatedProject.name}" updated successfully!'),
        ),
      );
      _loadProjectData(); // Refresh the project data
    }
  }

  Future<void> _addTask() async {
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
      _loadProjectData(); // Refresh the project data to show new task
    }
  }

  void _createChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create chat coming soon!')),
    );
  }

  void _addMember() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add member coming soon!')),
    );
  }

  void _navigateToTasksList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TasksListPage(
          projectId: widget.projectId,
          projectName: _project?.name,
        ),
      ),
    );
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
              leading: const Icon(Icons.person_add, color: Colors.orange),
              title: const Text('Add Member'),
              onTap: () {
                Navigator.pop(context);
                _manageUsers();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _manageUsers() async {
    final bool? wasChanged = await showDialog<bool>(
      context: context,
      builder: (context) => ManageProjectUsersDialog(
        projectId: widget.projectId,
        currentMembers: _projectMembers,
      ),
    );

    if (wasChanged == true) {
      // Reload project data to refresh members list
      _loadProjectData();
    }
  }

  void _showMemberDetails(User member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (member.email != null) ...[
              Text('Email: ${member.email}'),
              const SizedBox(height: 8),
            ],
            if (member.role != null) ...[
              Text('Role: ${member.role!.name}'),
              Text('Level: ${member.role!.level}'),
              const SizedBox(height: 8),
            ],
            if (member.accessType != null) ...[
              Text('Access Type: ${member.accessType}'),
              const SizedBox(height: 8),
            ],
            if (member.joinedProject != null)
              Text('Joined: ${_formatDate(member.joinedProject!)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
