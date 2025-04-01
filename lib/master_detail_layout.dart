import 'package:flutter/material.dart';
import 'package:project_organizer/project_provider.dart';
import 'package:provider/provider.dart';
import 'project_list_screen.dart';
import 'kanban_screen.dart';
import 'project_edit_screen.dart';

class MasterDetailLayout extends StatefulWidget {
  const MasterDetailLayout({super.key});

  @override
  State<MasterDetailLayout> createState() => _MasterDetailLayoutState();
}

class _MasterDetailLayoutState extends State<MasterDetailLayout> {
  bool _isMasterPaneVisible = true;

  // Helper to build the master pane (project list)
  Widget _buildMasterPane(BuildContext context) {
    const double masterPaneWidth = 250.0;

    return Visibility(
      visible: _isMasterPaneVisible,
      child: SizedBox(
        width: masterPaneWidth,
        child: Material(
          elevation: 1.0, // Add separation
          child: Column(
            children: [
              // Add Project Button
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to edit screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProjectEditScreen(),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Project'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1),
              // Project List takes remaining space
              const Expanded(child: ProjectListScreen()),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to build the detail pane (Kanban or placeholder)
  Widget _buildDetailPane(BuildContext context) {
    return Expanded(
      child: Consumer<ProjectProvider>(
        builder: (context, provider, child) {
          final selectedProject = provider.selectedProject;

          // Show Kanban if a project is selected (check String ID)
          if (selectedProject != null && selectedProject.id.isNotEmpty) {
            // Use ValueKey with the String ID to force rebuild when project changes
            return KanbanScreen(
              key: ValueKey(selectedProject.id),
              projectId: selectedProject.id, // Pass String ID
              projectName: selectedProject.name,
            );
          } else {
            // Show placeholder if no project is selected
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.view_kanban_outlined,
                      size: 72,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Select a project',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: Theme.of(context).disabledColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a project from the list on the left to see its tasks.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double breakpoint = 700.0; // Breakpoint for layout change

        // Wide screen: Master-Detail
        if (constraints.maxWidth >= breakpoint) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Kanban Projects (Hive)'),
              leading: IconButton(
                // Add the button to the AppBar
                icon: Icon(
                  _isMasterPaneVisible
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                ),
                onPressed: () {
                  setState(() {
                    _isMasterPaneVisible = !_isMasterPaneVisible;
                  });
                },
              ),
            ),
            body: Row(
              children: [
                _buildMasterPane(context),
                if (_isMasterPaneVisible)
                  const VerticalDivider(width: 1, thickness: 1), // Separator
                _buildDetailPane(context),
              ],
            ),
          );
        }
        // Narrow screen: List only, FAB for add
        else {
          return Scaffold(
            appBar: AppBar(title: const Text('Kanban Projects (Hive)')),
            body: const ProjectListScreen(), // Show only the list
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                // Navigate to edit screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProjectEditScreen(),
                    fullscreenDialog: true,
                  ),
                );
              },
              tooltip: 'Add New Project',
              child: const Icon(Icons.add),
            ),
          );
        }
      },
    );
  }
}
