// lib/pages/page-project-detail.dart
import 'package:flutter/material.dart';
import '../model/project_model.dart';
import '../model/task_model.dart';
import '../service/task_service.dart';
import '../components/task_list_component.dart';

class PageProjectDetail extends StatefulWidget {
  final Project project;

  const PageProjectDetail({super.key, required this.project});

  @override
  State<PageProjectDetail> createState() => _PageProjectDetailState();
}

class _PageProjectDetailState extends State<PageProjectDetail> {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  bool _isLoadingTasks = true;
  String? _tasksError;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      setState(() {
        _isLoadingTasks = true;
        _tasksError = null;
      });

      final tasks = await _taskService.fetchTasksByProject(widget.project.id);

      setState(() {
        _tasks = tasks;
        _isLoadingTasks = false;
      });
    } catch (e) {
      setState(() {
        _tasksError = e.toString();
        _isLoadingTasks = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.project.name ?? 'Project Details')),
      body: RefreshIndicator(
        onRefresh: _fetchTasks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProjectDetails(),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Tasks section
                _isLoadingTasks
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                    : _tasksError != null
                    ? _buildTasksErrorWidget()
                    : TaskListComponent(
                      title: 'Project Tasks',
                      tasks: _tasks,
                      onTasksChanged: _fetchTasks,
                      showProject:
                          false, // Don't show project name since we're in project context
                      projectId:
                          widget.project.id, // Link new tasks to this project
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Details',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildDetailItem('ID', widget.project.id.toString()),
        _buildDetailItem(
          'Organisation',
          widget.project.organisationName ??
              'Organisation #${widget.project.organisation}',
        ),
        if (widget.project.deadline != null)
          _buildDetailItem('Deadline', _formatDate(widget.project.deadline!)),
        _buildDetailItem(
          'Priority',
          _getPriorityLabel(widget.project.priority),
        ),
        if (widget.project.event != null)
          _buildDetailItem('Event ID', widget.project.event.toString()),
      ],
    );
  }

  Widget _buildTasksErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading tasks: $_tasksError'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTasks,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    final DateTime dateTime = DateTime.parse(date);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 0:
        return 'Low';
      case 1:
        return 'Medium';
      case 2:
        return 'High';
      case 3:
        return 'Urgent';
      default:
        return 'Unknown ($priority)';
    }
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
