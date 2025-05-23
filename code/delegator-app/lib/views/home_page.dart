// lib/views/home_page.dart

import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/event.dart';
import 'project_detail_page.dart';
import 'projects_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  String? _errorMessage;

  List<Project> _recentProjects = [];
  List<Task> _upcomingTasks = [];
  List<Event> _todayEvents = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load data in parallel
      final futures = await Future.wait([
        ServiceRegistry().projectService.getAll(),
        ServiceRegistry().taskService.getAll(),
        ServiceRegistry().eventService.getAll(),
      ]);

      final projects = futures[0] as List<Project>;
      final tasks = futures[1] as List<Task>;
      final events = futures[2] as List<Event>;

      setState(() {
        _recentProjects = projects.take(5).toList();
        _upcomingTasks = tasks.take(5).toList();
        _todayEvents =
            events.where((event) {
              final today = DateTime.now();
              return event.start.day == today.day &&
                  event.start.month == today.month &&
                  event.start.year == today.year;
            }).toList();
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
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ServiceRegistry().authService.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
          ),
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
              'Error loading dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildQuickStats(),
            const SizedBox(height: 20),
            _buildTodayEventsCard(),
            const SizedBox(height: 20),
            _buildRecentProjectsCard(),
            const SizedBox(height: 20),
            _buildUpcomingTasksCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
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
            Text(
              'Welcome back!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Here\'s what\'s happening today',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Navigate to all projects page
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProjectsPage()),
              );
            },
            child: _buildStatCard(
              'Projects',
              _recentProjects.length.toString(),
              Icons.work,
              Colors.green,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Tasks',
            _upcomingTasks.length.toString(),
            Icons.task,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Events Today',
            _todayEvents.length.toString(),
            Icons.event,
            Colors.purple,
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

  Widget _buildTodayEventsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Events',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_todayEvents.isEmpty)
              Text(
                'No events scheduled for today',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ..._todayEvents.map((event) => _buildEventTile(event)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTile(Event event) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: event.isGig ? Colors.orange : Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title ?? 'Untitled Event',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${_formatTime(event.start)} - ${_formatTime(event.end)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentProjectsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.work, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recent Projects',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to projects page
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProjectsPage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.add, color: Colors.green, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_recentProjects.isEmpty)
              Text(
                'No projects available',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ..._recentProjects
                  .map((project) => _buildProjectTile(project))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectTile(Project project) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.green[100],
        child: Icon(Icons.work, color: Colors.green[700]),
      ),
      title: Text(project.name ?? 'Untitled Project'),
      subtitle: Text('Priority: ${project.priority}'),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // Navigate to project detail page
        if (project.id != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => ProjectDetailPage(
                    projectId: project.id!,
                    projectName: project.name,
                  ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project ID not available')),
          );
        }
      },
    );
  }

  Widget _buildUpcomingTasksCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.task, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Upcoming Tasks',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_upcomingTasks.isEmpty)
              Text(
                'No tasks available',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ..._upcomingTasks.map((task) => _buildTaskTile(task)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(Task task) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.orange[100],
        child: Icon(Icons.task, color: Colors.orange[700]),
      ),
      title: Text(task.title),
      subtitle:
          task.deadline != null
              ? Text('Due: ${_formatDate(task.deadline!)}')
              : null,
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Open task: ${task.title}')));
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
