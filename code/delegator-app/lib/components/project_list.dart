// lib/components/project_list.dart
import 'package:flutter/material.dart';
import '../service/event_service.dart';

class ProjectList extends StatelessWidget {
  final List<Project> projects;
  final Function(Project)? onProjectTap;

  const ProjectList({super.key, required this.projects, this.onProjectTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: 8.0,
          ),
          child: Text(
            'My Projects',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child:
              projects.isEmpty
                  ? const Center(child: Text('No projects available'))
                  : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      return _buildProjectCard(projects[index]);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(Project project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          if (onProjectTap != null) {
            onProjectTap!(project);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                color: _getPriorityColor(project.priority),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project #${project.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (project.organisationName != null)
                      Text(
                        'Organisation: ${project.organisationName}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    if (project.deadline != null)
                      Text(
                        'Deadline: ${project.deadline}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (project.eventId != null)
                const Icon(Icons.event, color: Colors.blue, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
