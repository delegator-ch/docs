// lib/pages/page-home.dart
import 'package:flutter/material.dart';
import '../components//preview_list_components.dart';
import '../model/project_model.dart';
import 'page-project-detail.dart';
import 'page-all-projects.dart';

class PageHome extends StatefulWidget {
  const PageHome({super.key});

  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  // Sample project data
  final List<Project> _projects = [
    Project(
      id: 1,
      name: 'Mobile App Development',
      organisation: 'TechCorp',
      created: '2024-05-01',
    ),
    Project(
      id: 2,
      name: 'Website Redesign',
      organisation: 'DesignStudio',
      created: '2024-05-05',
    ),
    Project(
      id: 3,
      name: 'Marketing Campaign',
      organisation: 'MarketingPros',
      created: '2024-05-10',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Divider(height: 1),
              const SizedBox(height: 16),
              PreviewListComponent(
                title: 'Projects',
                items:
                    _projects.take(3).map((project) {
                      return PreviewListItem(
                        title: project.name,
                        subtitle: project.organisation,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      PageProjectDetail(project: project),
                            ),
                          );
                        },
                      );
                    }).toList(),
                onViewAllPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => PageAllProjects(projects: _projects),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Add more sections or components here as needed
            ],
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
}
