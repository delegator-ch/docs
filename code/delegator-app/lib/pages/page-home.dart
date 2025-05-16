// lib/pages/page-home.dart
import 'package:flutter/material.dart';
import '../components//preview_list_components.dart';
import '../model/project_model.dart';
import '../service/project_service.dart'; // Import the new project service
import 'page-project-detail.dart';
import 'page-all-projects.dart';

class PageHome extends StatefulWidget {
  const PageHome({super.key});

  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  final ProjectService _projectService = ProjectService();
  List<Project> _projects = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final projects = await _projectService.fetchProjects();

      setState(() {
        _projects = projects;
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchProjects,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _isLoading
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                    : _error != null
                    ? _buildErrorWidget()
                    : _projects.isEmpty
                    ? _buildEmptyProjectsWidget()
                    : _buildProjectsList(),
                const SizedBox(height: 16),
                // Add more sections or components here as needed
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
              onPressed: _fetchProjects,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProjectsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No projects available', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
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
                  // Refresh projects when returning from project detail
                  _fetchProjects();
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
