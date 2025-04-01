import 'package:hive/hive.dart';
import 'package:project_organizer/task.dart';
import '../constants.dart'; // For TaskStatus

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 1; // Unique ID for Task

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      projectId: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String,
      dueDate: fields[4] as DateTime?,
      status:
          fields[5]
              as TaskStatus, // Hive reads enum using its registered adapter
      order: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(7) // Number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.dueDate)
      ..writeByte(5)
      ..write(obj.status) // Hive writes enum using its registered adapter
      ..writeByte(6)
      ..write(obj.order);
  }
}
