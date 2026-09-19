import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:consistency_builder/analytics_screen.dart';
import 'package:consistency_builder/achievement_screen.dart';
import 'package:consistency_builder/edit_screen.dart';
import 'package:consistency_builder/goals_screen.dart';
import 'package:consistency_builder/home_screen.dart';
import 'package:consistency_builder/progress_screen.dart';
import 'package:consistency_builder/services/notification_service.dart';
import 'package:consistency_builder/services/temporary_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (const bool.fromEnvironment('dart.library.js_util') == false) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await NotificationService.instance.initialize();
  await TemporaryStorage.instance.initialize();
  runApp(const ConsistencyBuilderApp());
}

class ConsistencyBuilderApp extends StatelessWidget {
  const ConsistencyBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consistency Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F766E),
              brightness: Brightness.light,
              surface: const Color(0xFFF5F7F6),
            ).copyWith(
              primary: const Color(0xFF0F766E),
              onPrimary: Colors.white,
              primaryContainer: const Color(0xFFD7F2ED),
              surfaceContainerHighest: const Color(0xFFE8EEEC),
            ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F7F6),
          foregroundColor: Color(0xFF102A2A),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    ProgressScreen(),
    GoalsScreen(),
    AnalyticsScreen(),
    AchievementScreen(),
    EditScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  static String _appTitleForIndex(int index) {
    switch (index) {
      case 1:
        return 'Progress';
      case 2:
        return 'Goals';
      case 3:
        return 'Analytics';
      case 4:
        return 'Achievement';
      case 5:
        return 'Edit';
      default:
        return 'Consistency Builder';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appTitleForIndex(_selectedIndex)),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            label: 'Achievement',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            label: 'Edit',
          ),
        ],
      ),
    );
  }
}
