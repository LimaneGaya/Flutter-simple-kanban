import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_organizer/task.dart';
import 'package:project_organizer/task_provider.dart';
import 'package:provider/provider.dart';
import '../constants.dart'; // For TaskStatus, generateUniqueId

class TaskEditDialog extends StatefulWidget {
  final Task? task;
  final String projectId; // Should be String now
  final TaskStatus initialStatus;

  const TaskEditDialog({
    super.key,
    this.task,
    required this.projectId,
    this.initialStatus = TaskStatus.todo,
  });

  @override
  State<TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<TaskEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _dueDate;
  late TaskStatus _selectedStatus;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _dueDate = widget.task?.dueDate;
    _selectedStatus = widget.task?.status ?? widget.initialStatus;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final initialDate = _dueDate ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _dueDate) {
      setState(() {
        _dueDate = pickedDate;
      });
    }
  }

  void _saveTask(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);

      final task = Task(
        id: widget.task?.id ?? generateUniqueId(), // Generate ID if new
        projectId: widget.projectId, // Already string
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _dueDate,
        status: _selectedStatus,
        order:
            widget.task?.order ??
            0, // Provider calculates order for new tasks on add
      );

      Future<void> saveFuture;
      if (_isEditing) {
        saveFuture = taskProvider.updateTask(task);
      } else {
        saveFuture = taskProvider.addTask(task);
      }

      saveFuture
          .then((_) {
            if (context.mounted) Navigator.of(context).pop();
          })
          .catchError((error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error saving task: ${error.toString()}'),
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
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Task' : 'New Task'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Enter task title',
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter task description',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dueDate == null
                          ? 'No due date'
                          : 'Due: ${DateFormat.yMd().format(_dueDate!)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (_dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      iconSize: 18,
                      onPressed: () => setState(() => _dueDate = null),
                      tooltip: 'Clear Due Date',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  TextButton(
                    child: Text(_dueDate == null ? 'Set Date' : 'Change'),
                    onPressed: () => _selectDueDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<TaskStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items:
                    taskStatuses.map<DropdownMenuItem<TaskStatus>>((
                      TaskStatus status,
                    ) {
                      return DropdownMenuItem<TaskStatus>(
                        value: status,
                        child: Text(statusToString(status)),
                      );
                    }).toList(),
                onChanged: (TaskStatus? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedStatus = newValue;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text(_isEditing ? 'Save Changes' : 'Create Task'),
          onPressed: () => _saveTask(context),
        ),
      ],
    );
  }
}
