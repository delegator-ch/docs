// lib/pages/page-all-tasks.dart
import 'package:flutter/material.dart';
import '../model/task_model.dart';
import '../service/task_service.dart';
import '../components/task_list_component.dart';

class PageAllTasks extends StatefulWidget {
  const PageAllTasks({super.key});

  @override
  State<PageAllTasks> createState() => _PageAllTasksState();
}

class _PageAllTasksState extends State<PageAllTasks> {
  final TaskService _taskService = TaskService();
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final tasks = await _taskService.fetchTasks();

      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchTasks),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTasks,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorWidget()
                : _buildTaskList(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
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

  Widget _buildTaskList() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: TaskListComponent(
          title: 'Tasks',
          tasks: _tasks,
          onTasksChanged: _fetchTasks,
          showProject: true, // Show project name in the list
          onViewAllPressed: null, // Already on the all tasks page
        ),
      ),
    );
  }
}
