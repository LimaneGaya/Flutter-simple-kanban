// No Hive annotations needed for manual adapters
// No need to extend HiveObject unless you specifically want its features
// separate from adapters (less common with manual approach)
class Project {
  String id;
  String name;
  String description;
  DateTime? startDate;
  DateTime? endDate;

  Project({
    required this.id,
    required this.name,
    this.description = '',
    this.startDate,
    this.endDate,
  });
}
