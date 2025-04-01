import 'package:hive/hive.dart';
import 'package:project_organizer/project.dart';

class ProjectAdapter extends TypeAdapter<Project> {
  @override
  final int typeId = 0; // Unique ID for Project

  @override
  Project read(BinaryReader reader) {
    final numOfFields =
        reader.readByte(); // Read field count (optional but good practice)
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Project(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      // Read DateTime fields carefully, handling nulls
      startDate: fields[3] as DateTime?,
      endDate: fields[4] as DateTime?,
    );
    /* // Alternative more explicit read:
    final id = reader.readString();
    final name = reader.readString();
    final description = reader.readString();
    final hasStartDate = reader.readBool();
    final startDate = hasStartDate ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null;
    final hasEndDate = reader.readBool();
    final endDate = hasEndDate ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null;

    return Project(
        id: id,
        name: name,
        description: description,
        startDate: startDate,
        endDate: endDate
    );
    */
  }

  @override
  void write(BinaryWriter writer, Project obj) {
    writer
      ..writeByte(5) // Number of fields
      ..writeByte(0) // Field index 0
      ..write(obj.id) // Write id (String)
      ..writeByte(1) // Field index 1
      ..write(obj.name) // Write name (String)
      ..writeByte(2) // Field index 2
      ..write(obj.description) // Write description (String)
      ..writeByte(3) // Field index 3
      ..write(obj.startDate) // Write startDate (DateTime? - Hive handles null)
      ..writeByte(4) // Field index 4
      ..write(obj.endDate); // Write endDate (DateTime? - Hive handles null)

    /* // Alternative more explicit write:
     writer.writeString(obj.id);
     writer.writeString(obj.name);
     writer.writeString(obj.description);

     writer.writeBool(obj.startDate != null); // Write flag for start date
     if (obj.startDate != null) {
       writer.writeInt(obj.startDate!.millisecondsSinceEpoch); // Write date if not null
     }

     writer.writeBool(obj.endDate != null); // Write flag for end date
     if (obj.endDate != null) {
       writer.writeInt(obj.endDate!.millisecondsSinceEpoch); // Write date if not null
     }
     */
  }
}
