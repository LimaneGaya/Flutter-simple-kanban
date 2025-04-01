import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_organizer/task.dart';
import '../constants.dart';

class TaskProvider with ChangeNotifier {
  final String projectId;

  Map<TaskStatus, List<Task>> _tasksByStatus = {};
  bool _isLoading = false;

  Map<TaskStatus, List<Task>> get tasksByStatus => _tasksByStatus;
  bool get isLoading => _isLoading;

  final Box<Task> _taskBox = Hive.box<Task>(tasksBox);

  TaskProvider(this.projectId) {
    loadTasks();
    _taskBox.listenable().addListener(_onTaskBoxChanged);
  }

  @override
  void dispose() {
    _taskBox.listenable().removeListener(_onTaskBoxChanged);
    super.dispose();
  }

  void _onTaskBoxChanged() {
    if (kDebugMode) {
      print("Task box changed, reloading tasks for project $projectId...");
    }
    _loadTasksFromBox();
    notifyListeners();
  }

  void _loadTasksFromBox() {
    // Filter tasks for the current project directly from the box values
    final projectTasks =
        _taskBox.values.where((task) => task.projectId == projectId).toList();

    // Reset the map
    final newTasksByStatus = <TaskStatus, List<Task>>{};
    for (var status in taskStatuses) {
      newTasksByStatus[status] = [];
    }

    // Populate the map
    for (var task in projectTasks) {
      if (newTasksByStatus.containsKey(task.status)) {
        newTasksByStatus[task.status]!.add(task);
      } else {
        if (kDebugMode) {
          print(
            "Warning: Task ${task.id} (Project $projectId) has unknown status '${task.status}'. Placing in 'To Do'.",
          );
        }
        newTasksByStatus[TaskStatus.todo]?.add(task);
      }
    }

    // Sort tasks within each status list by order
    newTasksByStatus.forEach((status, taskList) {
      taskList.sort((a, b) => a.order.compareTo(b.order));
    });

    _tasksByStatus = newTasksByStatus;
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners(); // Notify start
    try {
      _loadTasksFromBox();
    } catch (e) {
      if (kDebugMode) {
        print("Error loading tasks in provider for project $projectId: $e");
      }
      _tasksByStatus = {};
      for (var status in taskStatuses) {
        _tasksByStatus[status] = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify end
    }
  }

  int _getNextTaskOrder(TaskStatus status) {
    // Get tasks for the specific status *from the current state map*
    final tasksInStatus = _tasksByStatus[status] ?? [];
    if (tasksInStatus.isEmpty) {
      return 0;
    }
    // Find max order + 1
    int maxOrder = tasksInStatus
        .map((t) => t.order)
        .reduce((a, b) => a > b ? a : b);
    return maxOrder + 1;
  }

  Future<void> addTask(Task task) async {
    if (task.projectId != projectId) {
      if (kDebugMode) print("Error: Trying to add task with wrong project ID.");
      return;
    }
    if (task.id.isEmpty) {
      task.id = generateUniqueId();
      if (kDebugMode) print("Generated new ID for task: ${task.id}");
    }
    if (task.title.trim().isEmpty) {
      if (kDebugMode) print("Error adding task: Title cannot be empty.");
      return;
    }

    try {
      // Calculate order based on current state *before* saving
      task.order = _getNextTaskOrder(task.status);
      if (kDebugMode) {
        print(
          "Assigning order ${task.order} to new task ${task.id} in status ${task.status}",
        );
      }

      // Save to Hive using the task's ID as the key
      await _taskBox.put(task.id, task);
      if (kDebugMode) print("Task added/updated in Hive: ${task.id}");
      // Listener will handle UI update
    } catch (e) {
      if (kDebugMode) print("Error adding task ${task.id} to Hive: $e");
    }
  }

  Future<void> updateTask(Task task) async {
    if (task.projectId != projectId) {
      if (kDebugMode) print("Error: Updating task with wrong project ID.");
      return;
    }
    if (task.id.isEmpty) {
      if (kDebugMode) print("Error: Updating task with empty ID.");
      return;
    }
    if (task.title.trim().isEmpty) {
      if (kDebugMode) print("Error updating task: Title cannot be empty.");
      return;
    }

    try {
      // Use put with the task's ID, Hive handles the update
      await _taskBox.put(task.id, task);
      if (kDebugMode) print("Task updated in Hive: ${task.id}");
      // Listener will handle UI updates and resorting
    } catch (e) {
      if (kDebugMode) print("Error updating task ${task.id} in Hive: $e");
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (taskId.isEmpty) {
      if (kDebugMode) print("Error deleting task: Invalid ID.");
      return;
    }
    try {
      await _taskBox.delete(taskId);
      if (kDebugMode) print("Task deleted from Hive: $taskId");
      // Listener will handle UI update
    } catch (e) {
      if (kDebugMode) print("Error deleting task $taskId from Hive: $e");
    }
  }

  Future<void> moveTask(
    String taskId,
    TaskStatus oldStatus,
    int oldIndex,
    TaskStatus newStatus,
    int newIndex,
  ) async {
    // --- 1. Get the task object from Hive ---
    final taskToMove = _taskBox.get(taskId);

    if (taskToMove == null) {
      if (kDebugMode) {
        print("Error moving task: Task with ID $taskId not found in Hive box.");
      }
      _loadTasksFromBox(); // Try to recover state
      notifyListeners();
      return;
    }

    // --- 2. Update Task Status ---
    taskToMove.status = newStatus;

    // --- 3. Update Local State Map (Optimistically) ---
    // Remove from the old status list in the map
    _tasksByStatus[oldStatus]?.removeWhere((t) => t.id == taskId);

    // Get the destination list from the map
    final destinationList = _tasksByStatus[newStatus];
    if (destinationList == null) {
      if (kDebugMode) {
        print(
          "Error moving task: Destination list $newStatus not found in local state map.",
        );
      }
      _loadTasksFromBox(); // Reload state as recovery attempt
      notifyListeners();
      return;
    }

    // Adjust insertion index bounds
    if (newIndex < 0) newIndex = 0;
    if (newIndex > destinationList.length) newIndex = destinationList.length;

    // Insert into the new status list in the map
    destinationList.insert(newIndex, taskToMove);

    // --- 4. Recalculate Order and Identify Tasks for Hive Update ---
    List<Task> tasksToUpdateInHive = [];

    // Update order property for all tasks in the source list (if status changed)
    // Use the list from the *local state map* for order calculation
    if (oldStatus != newStatus) {
      _updateOrderInList(_tasksByStatus[oldStatus], tasksToUpdateInHive);
    }
    // Update order property for all tasks in the destination list
    // Use the list from the *local state map*
    _updateOrderInList(_tasksByStatus[newStatus], tasksToUpdateInHive);

    // --- 5. Persist Changes to Hive ---
    if (tasksToUpdateInHive.isNotEmpty) {
      if (kDebugMode) {
        print(
          "Saving order/status updates for ${tasksToUpdateInHive.length} tasks to Hive...",
        );
      }
      // Use putAll for efficiency
      Map<String, Task> updates = {
        for (var task in tasksToUpdateInHive) task.id: task,
      };
      await _taskBox.putAll(updates);
      if (kDebugMode) print("Hive updates complete.");
    } else if (oldStatus != newStatus) {
      // If only the moved task's status changed, ensure it's saved
      // Recalculate its order based on its new position in the *local state map*
      taskToMove.order =
          _tasksByStatus[newStatus]?.indexWhere((t) => t.id == taskId) ?? 0;
      if (kDebugMode) {
        print(
          "MoveTask: Only status changed or single item move. Saving task ${taskToMove.id} with status ${taskToMove.status} and order ${taskToMove.order}.",
        );
      }
      await _taskBox.put(taskToMove.id, taskToMove);
    }

    // --- 6. Notify UI ---
    // State (_tasksByStatus) is already updated locally. Notify listeners.
    notifyListeners();
  }

  // Helper to update the 'order' property based on list index
  // and collect tasks needing persistence.
  void _updateOrderInList(List<Task>? taskList, List<Task> tasksToUpdate) {
    if (taskList == null) return;
    for (int i = 0; i < taskList.length; i++) {
      // If the task's current order property doesn't match its index
      if (taskList[i].order != i) {
        taskList[i].order = i; // Update the order in the Task object
        // Mark this task for saving, avoid duplicates
        if (!tasksToUpdate.any((t) => t.id == taskList[i].id)) {
          tasksToUpdate.add(taskList[i]);
        } else {
          // If already added (e.g., status also changed), ensure the order value is updated
          final existingIndex = tasksToUpdate.indexWhere(
            (t) => t.id == taskList[i].id,
          );
          if (existingIndex != -1) {
            tasksToUpdate[existingIndex].order =
                i; // Update order on existing entry
          }
        }
      }
    }
  }
}
