import '../constants.dart'; // For TaskStatus

// No Hive annotations needed for manual adapters
class Task {
  String id;
  String projectId;
  String title;
  String description;
  DateTime? dueDate;
  TaskStatus status;
  int order;

  Task({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.dueDate,
    required this.status,
    this.order = 0,
  });
}
