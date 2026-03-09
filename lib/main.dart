import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'models/employee.dart';
import 'models/leave_record.dart';
import 'models/note_record.dart';
import 'router.dart';
import 'services/eula_service.dart';
import 'services/whats_new_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize EULA state
  await EulaService.instance.init();

  // Initialize What's New state
  await WhatsNewService.instance.init();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(EmployeeAdapter());
  Hive.registerAdapter(LeaveTypeAdapter());
  Hive.registerAdapter(LeaveRecordAdapter());
  Hive.registerAdapter(NoteTypeAdapter());
  Hive.registerAdapter(NoteRecordAdapter());

  // Open Hive boxes
  await Hive.openBox<Employee>('employees');
  await Hive.openBox<LeaveRecord>('leave_records');
  await Hive.openBox<NoteRecord>('note_records');

  runApp(
    const ProviderScope(
      child: AlinaNTWorkApp(),
    ),
  );
}

class AlinaNTWorkApp extends StatelessWidget {
  const AlinaNTWorkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AlinaNTWork',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
