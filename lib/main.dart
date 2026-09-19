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
    const bgDark = Color(0xFF071B2D);
    const bgMid = Color(0xFF102C46);
    const accent = Color(0xFF8AB8FF);
    const accentSoft = Color(0xFFB9D9FF);

    return MaterialApp(
      title: 'Consistency Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
          surface: bgMid,
        ).copyWith(
          primary: accent,
          onPrimary: const Color(0xFF061626),
          primaryContainer: const Color(0xFF113661),
          secondary: const Color(0xFF9FC7FF),
          onSecondary: const Color(0xFF061626),
          surfaceContainerHighest: const Color(0xFF163457),
          onSurface: const Color(0xFFEAF4FF),
          onSurfaceVariant: const Color(0xFFB9D9FF),
        ),
        scaffoldBackgroundColor: bgDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFEAF4FF),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF122B4E).withValues(alpha: 0.82),
          elevation: 0,
          margin: EdgeInsets.zero,
          shadowColor: accent.withValues(alpha: 0.22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: accentSoft.withValues(alpha: 0.18), width: 1),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0C1F38),
          indicatorColor: accent.withValues(alpha: 0.2),
          surfaceTintColor: Colors.transparent,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? const Color(0xFFB9D9FF) : const Color(0xFF9FBAD9),
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? const Color(0xFFEAF4FF) : const Color(0xFF9FBAD9),
              fontWeight: FontWeight.w600,
            );
          }),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: const Color(0xFF061626),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            shadowColor: accent.withValues(alpha: 0.55),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFEAF4FF),
            side: BorderSide(color: accentSoft.withValues(alpha: 0.75), width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFB9D9FF),
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
      extendBody: true,
      appBar: AppBar(
        title: Text(_appTitleForIndex(_selectedIndex)),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF071B2D),
              Color(0xFF0C213A),
              Color(0xFF122B4E),
            ],
          ),
        ),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8AB8FF).withValues(alpha: 0.18),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: NavigationBar(
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
        ),
      ),
    );
  }
}
