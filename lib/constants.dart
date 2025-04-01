import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

// Box Names
const String projectsBox = 'projects';
const String tasksBox = 'tasks';

// Task Status Enum
// Keep @HiveType for the adapter's typeId reference
@HiveType(typeId: 2)
enum TaskStatus { ideas, todo, inProgress, done }

// Task Status Helpers
String statusToString(TaskStatus status) {
  switch (status) {
    case TaskStatus.ideas:
      return 'Ideas';
    case TaskStatus.todo:
      return 'To Do';
    case TaskStatus.inProgress:
      return 'In Progress';
    case TaskStatus.done:
      return 'Done';
  }
}

TaskStatus stringToStatus(String statusStr) {
  switch (statusStr.toLowerCase()) {
    case 'ideas':
      return TaskStatus.ideas;
    case 'to do':
      return TaskStatus.todo;
    case 'in progress':
      return TaskStatus.inProgress;
    case 'done':
      return TaskStatus.done;
    default:
      return TaskStatus.todo;
  }
}

const List<TaskStatus> taskStatuses = [
  TaskStatus.ideas,
  TaskStatus.todo,
  TaskStatus.inProgress,
  TaskStatus.done,
];

// --- Manual Adapter for TaskStatus ---
class TaskStatusAdapter extends TypeAdapter<TaskStatus> {
  @override
  final int typeId = 2; // Must match @HiveType above

  @override
  TaskStatus read(BinaryReader reader) {
    // Read the index saved by write
    final index = reader.readByte();
    if (index >= 0 && index < TaskStatus.values.length) {
      return TaskStatus.values[index];
    }
    // Handle potential data corruption or future enum changes gracefully
    return TaskStatus.todo; // Default fallback
  }

  @override
  void write(BinaryWriter writer, TaskStatus obj) {
    // Write the index of the enum value
    writer.writeByte(obj.index);
  }
}

// --- ID Generation ---
const _uuid = Uuid();
String generateUniqueId() => _uuid.v4();
