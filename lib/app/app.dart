import 'package:flutter/material.dart';

import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/places/place_management_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/storage/app_database.dart';
import '../features/timeline/day_detail_screen.dart';
import 'app_dependencies.dart';
import 'app_theme.dart';

class DailyPatternApp extends StatelessWidget {
  const DailyPatternApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '하루 기록',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'KyoboHandwriting',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.ink,
          brightness: Brightness.light,
          surface: AppColors.surface,
          primary: AppColors.ink,
          secondary: AppColors.softBlue,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.ink,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.softBlue,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? AppColors.ink
                  : AppColors.muted,
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.ink,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
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
  int _refreshVersion = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        dependencies: widget.dependencies,
        refreshVersion: _refreshVersion,
        onOpenTodayRecords: _openTodayRecords,
        onOpenLatestInsight: _openInsightDetail,
      ),
      HistoryScreen(
        database: widget.dependencies.database,
        refreshVersion: _refreshVersion,
      ),
      PlaceManagementScreen(
        database: widget.dependencies.database,
        refreshVersion: _refreshVersion,
        onPlacesChanged: _refreshAll,
      ),
      SettingsScreen(
        dependencies: widget.dependencies,
        onDataChanged: _refreshAll,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titleForIndex(_selectedIndex))),
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
            label: '오늘',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: '돌아보기',
          ),
          NavigationDestination(
            icon: Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place),
            label: '자주 간 곳',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }

  void _refreshAll() {
    setState(() {
      _refreshVersion++;
    });
  }

  void _openTodayRecords() {
    final now = DateTime.now();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DayDetailScreen(
          database: widget.dependencies.database,
          date: now,
          appBarTitle: '오늘 기록',
          title: '오늘 기록',
          body: '오늘 기기 안에 쌓이고 있는 위치 기록과 머문 곳을 확인해요.',
          showRawRecords: true,
        ),
      ),
    );
  }

  void _openInsightDetail(Insight insight) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DayDetailScreen(
          database: widget.dependencies.database,
          date: insight.date,
          title: insight.title,
          body: insight.body,
        ),
      ),
    );
  }

  String _titleForIndex(int index) {
    return switch (index) {
      0 => '오늘',
      1 => '돌아보기',
      2 => '자주 간 곳',
      _ => '설정',
    };
  }
}
