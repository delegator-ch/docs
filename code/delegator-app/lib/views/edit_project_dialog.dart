// lib/views/edit_project_dialog.dart

import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import '../models/project.dart';
import '../models/organisation.dart';

class EditProjectDialog extends StatefulWidget {
  final Project project;

  const EditProjectDialog({Key? key, required this.project}) : super(key: key);

  @override
  _EditProjectDialogState createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<EditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  List<Organisation> _organisations = [];
  Organisation? _selectedOrganisation;
  int _selectedPriority = 3;
  int _selectedStatus = 1;
  DateTime? _selectedDeadline;
  bool _isLoading = false;
  bool _isLoadingOrganisations = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadOrganisations();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    _nameController.text = widget.project.name ?? '';
    _selectedPriority = widget.project.priority;
    _selectedStatus = widget.project.status;
    _selectedDeadline = widget.project.deadline;
  }

  Future<void> _loadOrganisations() async {
    try {
      final organisations =
          await ServiceRegistry().organisationService.getAll();
      setState(() {
        _organisations = organisations;
        _selectedOrganisation = organisations.firstWhere(
          (org) => org.id == widget.project.organisationId,
          orElse: () => organisations.isNotEmpty
              ? organisations.first
              : Organisation(id: -1),
        );
        _isLoadingOrganisations = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load organisations: $e';
        _isLoadingOrganisations = false;
      });
    }
  }

  Future<void> _updateProject() async {
    if (!_formKey.currentState!.validate() || _selectedOrganisation == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final updatedProject = Project(
        id: widget.project.id,
        name: _nameController.text.trim(),
        organisationId: _selectedOrganisation!.id,
        priority: _selectedPriority,
        status: _selectedStatus,
        deadline: _selectedDeadline,
        event: widget.project.event,
        eventDetails: widget.project.eventDetails,
        organisation: widget.project.organisation,
        chat: widget.project.chat,
      );

      final result =
          await ServiceRegistry().projectService.update(updatedProject);
      Navigator.of(context).pop(result);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDeadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select project deadline',
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Project'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name *',
                  hintText: 'Enter project name',
                  prefixIcon: Icon(Icons.work),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a project name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Organisation Dropdown
              if (_isLoadingOrganisations)
                const Center(child: CircularProgressIndicator())
              else if (_organisations.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('No organisations available'),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<Organisation>(
                  value: _selectedOrganisation,
                  decoration: const InputDecoration(
                    labelText: 'Organisation *',
                    prefixIcon: Icon(Icons.business),
                  ),
                  items: _organisations.map((org) {
                    return DropdownMenuItem<Organisation>(
                      value: org,
                      child: Text(org.name ?? 'Organisation ${org.id}'),
                    );
                  }).toList(),
                  onChanged: (Organisation? newValue) {
                    setState(() {
                      _selectedOrganisation = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select an organisation';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),

              // Priority Dropdown
              DropdownButtonFormField<int>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: Icon(Icons.priority_high),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('🔴 URGENT')),
                  DropdownMenuItem(value: 2, child: Text('🟠 HIGH')),
                  DropdownMenuItem(value: 3, child: Text('🟡 MEDIUM')),
                  DropdownMenuItem(value: 4, child: Text('🔵 LOW')),
                  DropdownMenuItem(value: 5, child: Text('🟢 LOWEST')),
                ],
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedPriority = newValue ?? 3;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Status Dropdown
              DropdownButtonFormField<int>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.timeline),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('🟠 Planning')),
                  DropdownMenuItem(value: 2, child: Text('🟢 Active')),
                  DropdownMenuItem(value: 3, child: Text('🔵 Completed')),
                ],
                onChanged: (int? newValue) {
                  setState(() {
                    _selectedStatus = newValue ?? 1;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Deadline Selection
              InkWell(
                onTap: _selectDeadline,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Deadline (Optional)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _selectedDeadline != null
                                  ? _formatDate(_selectedDeadline!)
                                  : 'No deadline set',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedDeadline != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _selectedDeadline = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              _isLoading || _organisations.isEmpty ? null : _updateProject,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Update Project'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
