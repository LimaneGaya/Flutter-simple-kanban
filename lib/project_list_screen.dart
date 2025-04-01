import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:project_organizer/project.dart';
import 'package:project_organizer/project_provider.dart';
import 'package:provider/provider.dart';
import 'project_edit_screen.dart';
import 'kanban_screen.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

  void _navigateToProjectEdit(BuildContext context, {Project? project}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectEditScreen(project: project),
        fullscreenDialog: true,
      ),
    );
  }

  void _navigateToKanban(BuildContext context, Project project) {
    // Project ID is now String, check if empty
    if (project.id.isEmpty) {
      if (kDebugMode) {
        print(
          "Error: Cannot navigate to Kanban for project with empty ID: ${project.name}",
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Project data is incomplete.')),
      );
      return;
    }

    // Set selected project in the provider
    Provider.of<ProjectProvider>(context, listen: false).selectProject(project);

    // Navigate on narrow screens
    if (MediaQuery.of(context).size.width < 700) {
      // Use same breakpoint as MasterDetailLayout
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => KanbanScreen(
                projectId: project.id, // Pass String ID
                projectName: project.name,
              ),
        ),
      );
    }
    // On wider screens, MasterDetailLayout handles showing the detail pane
  }

  void _deleteProject(BuildContext context, Project project) async {
    // Project ID is now String, check if empty
    if (project.id.isEmpty) {
      if (kDebugMode) {
        print("Error: Cannot delete project with empty ID: ${project.name}");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Project data is incomplete.')),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Text(
              'Delete project "${project.name}" and all its tasks? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );

    // If confirmed, call provider's delete method
    if (confirm == true) {
      try {
        // Use context safely after async gap
        await Provider.of<ProjectProvider>(
          // ignore: use_build_context_synchronously
          context,
          listen: false,
        ).deleteProject(project.id); // Pass String ID
        // ignore: use_build_context_synchronously
        if (!context.mounted) return; // Check if widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (kDebugMode) print("Error deleting project ${project.id}: $e");
        // ignore: use_build_context_synchronously
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting project: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        // Loading indicator
        if (provider.isLoading && provider.projects.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Empty state message
        if (provider.projects.isEmpty && !provider.isLoading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 60,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No projects found.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first project to get started.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create Project'),
                    onPressed: () => _navigateToProjectEdit(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Project list
        return ListView.builder(
          itemCount: provider.projects.length,
          itemBuilder: (context, index) {
            final project = provider.projects[index];
            final bool isSelected =
                provider.selectedProject?.id ==
                project.id; // Compare String IDs

            return Card(
              color:
                  isSelected
                      ? Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.4)
                      : null,
              child: ListTile(
                title: Text(
                  project.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle:
                    project.description.isNotEmpty
                        ? Text(
                          project.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                        : null,
                selected: isSelected,
                onTap: () => _navigateToKanban(context, project),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _navigateToProjectEdit(context, project: project);
                    } else if (value == 'delete') {
                      _deleteProject(context, project);
                    }
                  },
                  itemBuilder:
                      (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit Project'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            title: Text(
                              'Delete Project',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ),
                      ],
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Project options',
                ),
              ),
            );
          },
        );
      },
    );
  }
}
