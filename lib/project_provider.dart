import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_organizer/project.dart';
import 'package:project_organizer/task.dart';
import '../constants.dart';

class ProjectProvider with ChangeNotifier {
  bool _isLoading = false;
  Project? _selectedProject;
  List<Project> _projects = [];

  List<Project> get projects => _projects;
  bool get isLoading => _isLoading;
  Project? get selectedProject => _selectedProject;

  final Box<Project> _projectBox = Hive.box<Project>(projectsBox);
  final Box<Task> _taskBox = Hive.box<Task>(tasksBox);

  ProjectProvider() {
    loadProjects();
    _projectBox.listenable().addListener(_onProjectBoxChanged);
  }

  @override
  void dispose() {
    _projectBox.listenable().removeListener(_onProjectBoxChanged);
    super.dispose();
  }

  void _onProjectBoxChanged() {
    if (kDebugMode) {
      print("Project box changed, reloading projects in provider...");
    }
    _loadProjectsFromBox();
    if (_selectedProject != null &&
        !_projectBox.containsKey(_selectedProject!.id)) {
      if (kDebugMode) {
        print(
          "Selected project ${_selectedProject!.id} no longer exists, clearing selection.",
        );
      }
      _selectedProject = null;
    }
    notifyListeners();
  }

  void _loadProjectsFromBox() {
    _projects = _projectBox.values.toList();
    _projects.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  }

  Future<void> loadProjects() async {
    _isLoading = true;
    notifyListeners();
    try {
      _loadProjectsFromBox();
    } catch (e) {
      if (kDebugMode) print("Error loading projects in provider: $e");
      _projects = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectProject(Project? project) {
    if (_selectedProject?.id != project?.id) {
      _selectedProject = project;
      notifyListeners();
    }
  }

  Future<void> addProject(Project project) async {
    if (project.id.isEmpty) {
      project.id = generateUniqueId();
      if (kDebugMode) print("Generated new ID for project: ${project.id}");
    }
    if (project.name.trim().isEmpty) {
      if (kDebugMode) print("Error adding project: Name cannot be empty.");
      return;
    }
    try {
      // Use key (id) to put the object into the box
      await _projectBox.put(project.id, project);
      if (kDebugMode) print("Project added/updated in Hive: ${project.id}");
    } catch (e) {
      if (kDebugMode) print("Error adding project ${project.id} to Hive: $e");
    }
  }

  Future<void> updateProject(Project project) async {
    // put handles both add and update
    await addProject(project);
    // Update selected project reference if needed
    if (_selectedProject?.id == project.id) {
      _selectedProject = project; // Update the instance
    }
  }

  Future<void> deleteProject(String projectId) async {
    if (projectId.isEmpty) {
      if (kDebugMode) print("Error deleting project: Invalid ID.");
      return;
    }
    try {
      // Find tasks associated with the project
      final tasksToDelete =
          _taskBox.values.where((task) => task.projectId == projectId).toList();

      // Get keys of tasks to delete
      List<String> taskKeysToDelete =
          tasksToDelete.map((task) => task.id).toList();

      // Delete associated tasks first
      if (taskKeysToDelete.isNotEmpty) {
        if (kDebugMode) {
          print(
            "Deleting ${taskKeysToDelete.length} tasks for project $projectId...",
          );
        }
        // Use deleteAll with the list of keys
        await _taskBox.deleteAll(taskKeysToDelete);
        if (kDebugMode) print("Tasks deleted.");
      }

      // Delete the project itself
      await _projectBox.delete(projectId);
      if (kDebugMode) print("Project deleted from Hive: $projectId");

      // Clear selection if the deleted project was selected
      // The listener might handle this, but explicit check is safer
      if (_selectedProject?.id == projectId) {
        _selectedProject = null;
        // Listener will notify UI
      }
    } catch (e) {
      if (kDebugMode) print("Error deleting project $projectId from Hive: $e");
    }
  }
}
