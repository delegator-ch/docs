// lib/pages/page-all-projects.dart
import 'package:flutter/material.dart';
import '../model/project_model.dart';
import 'page-project-detail.dart';

class PageAllProjects extends StatelessWidget {
  final List<Project> projects;

  const PageAllProjects({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Projects')),
      body: ListView.separated(
        itemCount: projects.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final project = projects[index];
          return ListTile(
            title: Text(project.name ?? 'Unnamed Project'),
            subtitle: Text(project.organisationName ?? 'Unknown Organisation'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PageProjectDetail(project: project),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
