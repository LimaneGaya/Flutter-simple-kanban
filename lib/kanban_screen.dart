import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:project_organizer/project_provider.dart';
import 'package:project_organizer/task.dart';
import 'package:project_organizer/task_card.dart';
import 'package:project_organizer/task_edit_layout.dart';
import 'package:project_organizer/task_provider.dart';
import 'package:provider/provider.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import '../constants.dart';

class KanbanScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const KanbanScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  late final TaskProvider _taskProvider;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _taskProvider = TaskProvider(widget.projectId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showTaskEditDialog(
    BuildContext context, {
    Task? task,
    TaskStatus? initialStatus,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return ChangeNotifierProvider.value(
          value: _taskProvider,
          child: TaskEditDialog(
            task: task,
            projectId: widget.projectId,
            initialStatus: initialStatus ?? TaskStatus.todo,
          ),
        );
      },
    );
  }

  void _showTaskOptions(BuildContext context, Task task) {
    if (task.id.isEmpty) {
      if (kDebugMode) {
        print(
          "Error: Cannot show options for task with empty ID (Project ${widget.projectId}).",
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot perform action: Task ID missing.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Task'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showTaskEditDialog(context, task: task);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete Task',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (BuildContext confirmDialogContext) => AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: const Text(
                            'Are you sure you want to delete this task? This cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed:
                                  () => Navigator.of(
                                    confirmDialogContext,
                                  ).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed:
                                  () => Navigator.of(
                                    confirmDialogContext,
                                  ).pop(true),
                              child: Text(
                                'Delete',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                  );

                  if (confirm == true) {
                    try {
                      await _taskProvider.deleteTask(task.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task deleted'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (kDebugMode) {
                        print("Error deleting task ${task.id}: $e");
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error deleting task: ${e.toString()}',
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _onItemReorder(
    int oldItemIndex,
    int oldListIndex,
    int newItemIndex,
    int newListIndex,
  ) {
    if (oldListIndex < 0 ||
        oldListIndex >= taskStatuses.length ||
        newListIndex < 0 ||
        newListIndex >= taskStatuses.length) {
      if (kDebugMode) {
        print(
          "Error: Invalid list index during reorder. old=$oldListIndex, new=$newListIndex, project=${widget.projectId}",
        );
      }
      _taskProvider.loadTasks();
      return;
    }

    final oldStatus = taskStatuses[oldListIndex];
    final newStatus = taskStatuses[newListIndex];
    final taskList = _taskProvider.tasksByStatus[oldStatus];

    if (taskList == null ||
        oldItemIndex < 0 ||
        oldItemIndex >= taskList.length) {
      if (kDebugMode) {
        print(
          "Error: Invalid item index or task list during reorder. status=$oldStatus, index=$oldItemIndex, project=${widget.projectId}",
        );
      }
      _taskProvider.loadTasks();
      return;
    }

    final String taskToMoveId = taskList[oldItemIndex].id;

    if (taskToMoveId.isEmpty) {
      if (kDebugMode) {
        print(
          "Error: Task being moved has an empty ID. project=${widget.projectId}",
        );
      }
      _taskProvider.loadTasks();
      return;
    }

    _taskProvider.moveTask(
      taskToMoveId,
      oldStatus,
      oldItemIndex,
      newStatus,
      newItemIndex,
    );
  }

  void _onListReorder(int oldListIndex, int newListIndex) {
    if (kDebugMode) {
      print("List (column) reordering is currently disabled.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _taskProvider,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.projectName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              try {
                Provider.of<ProjectProvider>(
                  context,
                  listen: false,
                ).selectProject(null);
              } catch (e) {
                if (kDebugMode) {
                  print(
                    "Error accessing ProjectProvider during back navigation: $e",
                  );
                }
              }
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            tooltip: 'Back to Projects',
          ),
        ),
        body: Consumer<TaskProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            List<DragAndDropList> dragAndDropLists =
                taskStatuses.map((status) {
                  final tasks = provider.tasksByStatus[status] ?? [];

                  return DragAndDropList(
                    header: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 12.0,
                      ), // Reduced padding
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            statusToString(status),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            iconSize: 18.0, // Reduced icon size
                            onPressed:
                                () => _showTaskEditDialog(
                                  context,
                                  initialStatus: status,
                                ),
                            tooltip: 'Add Task to ${statusToString(status)}',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    children:
                        tasks.isEmpty
                            ? [
                              DragAndDropItem(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 12,
                                  ), // Reduced padding
                                  child: Center(
                                    child: Text(
                                      "Empty",
                                      style: TextStyle(
                                        color: Theme.of(context).disabledColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ),
                                canDrag: false,
                              ),
                            ]
                            : tasks.map((task) {
                              return DragAndDropItem(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2.0,
                                    horizontal: 6.0,
                                  ), // Reduced padding
                                  child: TaskCard(
                                    task: task,
                                    onTap:
                                        () => _showTaskEditDialog(
                                          context,
                                          task: task,
                                        ),
                                    onLongPress:
                                        () => _showTaskOptions(context, task),
                                  ),
                                ),
                              );
                            }).toList(),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.grey.shade200
                              : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(
                        8.0,
                      ), // Reduced radius
                    ),
                  );
                }).toList();

            return DragAndDropLists(
              children: dragAndDropLists,
              onItemReorder: _onItemReorder,
              onListReorder: _onListReorder,
              axis: Axis.horizontal,
              listWidth: 280, // Reduced list width
              listDraggingWidth: 280, // Reduced list dragging width
              listPadding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 12.0,
              ), // Reduced padding
              itemDivider: const SizedBox(height: 0),
              listDivider: const SizedBox(width: 8), // Reduced divider width
              listDividerOnLastChild: true,
              scrollController: _scrollController,
              itemDragOnLongPress: true,
              itemGhost: Opacity(
                opacity: 0.7,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8.0), // Reduced radius
                  ),
                  height: 60, // Reduced height
                  margin: const EdgeInsets.symmetric(
                    vertical: 2.0,
                    horizontal: 6.0,
                  ), // Reduced margin
                ),
              ),
              itemGhostOpacity: 1.0,
              listDragOnLongPress: false,
            );
          },
        ),
      ),
    );
  }
}
