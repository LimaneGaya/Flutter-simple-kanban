import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_organizer/project.dart';
import 'package:project_organizer/project_provider.dart';
import 'package:provider/provider.dart';
import '../constants.dart';

class ProjectEditScreen extends StatefulWidget {
  final Project? project;

  const ProjectEditScreen({super.key, this.project});

  @override
  State<ProjectEditScreen> createState() => _ProjectEditScreenState();
}

class _ProjectEditScreenState extends State<ProjectEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  DateTime? _startDate;
  DateTime? _endDate;

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.project?.description ?? '',
    );
    _startDate = widget.project?.startDate;
    _endDate = widget.project?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = (isStartDate ? _startDate : _endDate) ?? DateTime.now();
    final firstDate =
        isStartDate ? DateTime(2000) : (_startDate ?? DateTime(2000));
    final lastValidDate = DateTime(2101);
    final effectiveLastDate =
        (isStartDate && _endDate != null && _endDate!.isBefore(lastValidDate))
            ? _endDate!
            : lastValidDate;
    final validInitialDate =
        initialDate.isBefore(firstDate)
            ? firstDate
            : (initialDate.isAfter(effectiveLastDate)
                ? effectiveLastDate
                : initialDate);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: validInitialDate,
      firstDate: firstDate,
      lastDate: effectiveLastDate,
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = pickedDate;
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = null;
          }
        }
      });
    }
  }

  void _saveProject(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      final projectProvider = Provider.of<ProjectProvider>(
        context,
        listen: false,
      );

      final project = Project(
        id: widget.project?.id ?? generateUniqueId(), // Generate ID if new
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
      );

      // Use addProject for both create and update
      projectProvider
          .addProject(project)
          .then((_) {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          })
          .catchError((error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error saving project: ${error.toString()}'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fix the errors in the form.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Same build method as before ---
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Project' : 'New Project'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: () => _saveProject(context),
            tooltip: 'Save Project',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name *',
                  hintText: 'Enter the project name',
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Project name cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter a brief description',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24.0),
              Text(
                'Start Date (Optional)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4.0),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _startDate == null
                          ? 'Not set'
                          : DateFormat.yMMMd().format(_startDate!),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  if (_startDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      iconSize: 20,
                      onPressed: () => setState(() => _startDate = null),
                      tooltip: 'Clear Start Date',
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(_startDate == null ? 'Select' : 'Change'),
                    onPressed: () => _selectDate(context, true),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Text(
                'End Date (Optional)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4.0),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _endDate == null
                          ? 'Not set'
                          : DateFormat.yMMMd().format(_endDate!),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  if (_endDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      iconSize: 20,
                      onPressed: () => setState(() => _endDate = null),
                      tooltip: 'Clear End Date',
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(_endDate == null ? 'Select' : 'Change'),
                    onPressed: () => _selectDate(context, false),
                  ),
                ],
              ),
              const SizedBox(height: 32.0),
            ],
          ),
        ),
      ),
    );
  }
}
