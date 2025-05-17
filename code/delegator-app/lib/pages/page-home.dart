// lib/pages/page-home.dart
import 'package:flutter/material.dart';
import '../components/preview_list_components.dart';
import '../model/project_model.dart';
import '../model/task_model.dart';
import '../service/project_service.dart';
import '../service/task_service.dart';
import 'page-project-detail.dart';
import 'page-all-projects.dart';
import 'page-all-tasks.dart';
import '../components/task_list_component.dart';

class PageHome extends StatefulWidget {
  const PageHome({super.key});

  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  final ProjectService _projectService = ProjectService();
  final TaskService _taskService = TaskService();

  List<Project> _projects = [];
  List<Task> _tasks = [];

  bool _isLoadingProjects = true;
  bool _isLoadingTasks = true;

  String? _projectsError;
  String? _tasksError;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    _fetchProjects();
    _fetchTasks();
  }

  Future<void> _fetchProjects() async {
    try {
      setState(() {
        _isLoadingProjects = true;
        _projectsError = null;
      });

      final projects = await _projectService.fetchProjects();

      setState(() {
        _projects = projects;
        _isLoadingProjects = false;
      });
    } catch (e) {
      setState(() {
        _projectsError = e.toString();
        _isLoadingProjects = false;
      });
    }
  }

  Future<void> _fetchTasks() async {
    try {
      setState(() {
        _isLoadingTasks = true;
        _tasksError = null;
      });

      final tasks = await _taskService.fetchTasks();

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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Display tasks section
                _isLoadingTasks
                    ? _buildLoadingWidget('Loading tasks...')
                    : _tasksError != null
                    ? _buildErrorWidget(_tasksError!, _fetchTasks)
                    : _tasks.isEmpty
                    ? _buildEmptyTasksWidget()
                    : _buildTasksPreview(),

                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Display projects section
                _isLoadingProjects
                    ? _buildLoadingWidget('Loading projects...')
                    : _projectsError != null
                    ? _buildErrorWidget(_projectsError!, _fetchProjects)
                    : _projects.isEmpty
                    ? _buildEmptyProjectsWidget()
                    : _buildProjectsList(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text(
            'Home',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 8),
            Text('Error: $error', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTasksWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            const Text(
              'No tasks available',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create a new task to get started',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PageAllTasks()),
                ).then((_) => _fetchTasks());
              },
              child: const Text('Create Task'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksPreview() {
    // Take up to 3 tasks for preview
    final previewTasks = _tasks.take(3).toList();

    return TaskListComponent(
      title: 'Tasks',
      tasks: previewTasks,
      onTasksChanged: _fetchTasks,
      showProject: true,
      onViewAllPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PageAllTasks()),
        ).then((_) => _fetchTasks());
      },
    );
  }

  Widget _buildEmptyProjectsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            const Text(
              'No projects available',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create a new project to get started',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsList() {
    return PreviewListComponent(
      title: 'Projects',
      items:
          _projects.take(3).map((project) {
            return PreviewListItem(
              title: project.name ?? 'Unnamed Project',
              subtitle: project.organisationName ?? 'Unknown Organisation',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PageProjectDetail(project: project),
                  ),
                ).then((_) {
                  // Refresh projects and tasks when returning from project detail
                  _fetchProjects();
                  //_fetchTasks();
                });
              },
            );
          }).toList(),
      onViewAllPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PageAllProjects(projects: _projects),
          ),
        ).then((_) {
          // Refresh projects when returning from all projects
          _fetchProjects();
        });
      },
    );
  }
}
