import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:project_organizer/master_detail_layout.dart';
import 'package:project_organizer/project.dart';
import 'package:project_organizer/project_adapter.dart';
import 'package:project_organizer/project_provider.dart';
import 'package:project_organizer/task.dart';
import 'package:project_organizer/task_adapter.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'constants.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Manual Adapters (BEFORE opening boxes)
  Hive.registerAdapter(ProjectAdapter()); // Manual adapter instance
  Hive.registerAdapter(TaskAdapter()); // Manual adapter instance
  Hive.registerAdapter(
    TaskStatusAdapter(),
  ); // Manual adapter instance from constants

  // Open Hive Boxes
  await Hive.openBox<Project>(projectsBox);
  await Hive.openBox<Task>(tasksBox);

  if (kDebugMode) print("Hive initialized and boxes opened (Manual Adapters).");

  // Run the app
  runApp(const KanbanApp());
}

class KanbanApp extends StatelessWidget {
  const KanbanApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide ProjectProvider globally
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        // TaskProvider is provided locally within KanbanScreen where needed
      ],
      child: MaterialApp(
        title: 'Flutter Kanban Hive App (Manual)', // Updated title
        // --- Theming (Same as before) ---
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.light,
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          cardTheme: CardThemeData(
            elevation: 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.indigo, width: 2.0),
            ),
            filled: true,
            fillColor: Colors.grey.shade100.withValues(alpha: 0.8),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 12.0,
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.dark,
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          cardTheme: CardThemeData(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(color: Colors.tealAccent, width: 2.0),
            ),
            filled: true,
            fillColor: Colors.grey.shade800.withValues(alpha: 0.8),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 12.0,
            ),
          ),
        ),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        // Start with the responsive layout
        home: const MasterDetailLayout(),
      ),
    );
  }
}
