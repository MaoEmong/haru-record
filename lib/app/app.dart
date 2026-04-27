import 'package:flutter/material.dart';

import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/places/place_management_screen.dart';
import '../features/settings/settings_screen.dart';
import 'app_dependencies.dart';

class DailyPatternApp extends StatelessWidget {
  const DailyPatternApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Pattern',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF137C72),
          secondary: const Color(0xFFE68A2E),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8F4),
        useMaterial3: true,
      ),
      home: DailyPatternShell(dependencies: dependencies),
    );
  }
}

class DailyPatternShell extends StatefulWidget {
  const DailyPatternShell({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<DailyPatternShell> createState() => _DailyPatternShellState();
}

class _DailyPatternShellState extends State<DailyPatternShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(dependencies: widget.dependencies),
      HistoryScreen(database: widget.dependencies.database),
      PlaceManagementScreen(database: widget.dependencies.database),
      SettingsScreen(dependencies: widget.dependencies),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Pattern')),
      body: SafeArea(child: screens[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place),
            label: 'Places',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
