import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/places/place_management_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/storage/app_database.dart';
import '../features/timeline/day_activity_preview_repository.dart';
import '../features/timeline/day_detail_screen.dart';
import '../features/timeline/day_flow_playback_screen.dart';
import '../features/timeline/day_route_models.dart';
import 'app_dependencies.dart';
import 'app_providers.dart';
import 'app_theme.dart';

class DailyPatternApp extends StatelessWidget {
  const DailyPatternApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [appDependenciesProvider.overrideWithValue(dependencies)],
      child: MaterialApp(
        title: '하루 기록',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          textTheme: _appTextTheme(),
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.ink,
            brightness: Brightness.dark,
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
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: AppColors.background,
            indicatorColor: Colors.transparent,
            elevation: 0,
            height: 72,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                color: states.contains(WidgetState.selected)
                    ? AppColors.softBlue
                    : AppColors.muted,
                fontSize: 13,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                color: states.contains(WidgetState.selected)
                    ? AppColors.softBlue
                    : AppColors.muted,
                size: states.contains(WidgetState.selected) ? 25 : 23,
              ),
            ),
          ),
          listTileTheme: ListTileThemeData(
            iconColor: AppColors.ink,
            textColor: AppColors.ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppColors.blueGrey,
                width: 1.4,
              ),
            ),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.ink
                  : AppColors.muted,
            ),
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.softBlue
                  : AppColors.paleBlue,
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.softBlue,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              backgroundColor: AppColors.surface,
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
      ),
    );
  }
}

TextTheme _appTextTheme() {
  final base = Typography.material2021().white;
  return base.copyWith(
    headlineSmall: base.headlineSmall?.copyWith(fontSize: 25),
    titleLarge: base.titleLarge?.copyWith(fontSize: 23),
    titleMedium: base.titleMedium?.copyWith(fontSize: 17),
    titleSmall: base.titleSmall?.copyWith(fontSize: 15),
    bodyLarge: base.bodyLarge?.copyWith(fontSize: 17),
    bodyMedium: base.bodyMedium?.copyWith(fontSize: 15),
    bodySmall: base.bodySmall?.copyWith(fontSize: 13),
    labelLarge: base.labelLarge?.copyWith(fontSize: 15),
    labelMedium: base.labelMedium?.copyWith(fontSize: 13),
    labelSmall: base.labelSmall?.copyWith(fontSize: 12),
  );
}

class DailyPatternShell extends StatefulWidget {
  const DailyPatternShell({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<DailyPatternShell> createState() => _DailyPatternShellState();
}

class _DailyPatternShellState extends State<DailyPatternShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  int _refreshVersion = 0;
  int _homeEntryVersion = 0;
  bool _isSyncingRecords = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncStartupRecords();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncStartupRecords();
    }
  }

  Future<void> _syncStartupRecords() async {
    if (_isSyncingRecords) return;
    _isSyncingRecords = true;
    try {
      final result = await widget.dependencies.syncStartupRecords();
      if (!mounted || !result.hasChanges) return;
      _refreshAll();
    } catch (_) {
      // Startup sync is opportunistic; the background worker/manual action retries.
    } finally {
      _isSyncingRecords = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _confirmExit();
        if (shouldExit && mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [Expanded(child: _buildScreen(_selectedIndex))],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              if (index == 0 && _selectedIndex != 0) {
                _homeEntryVersion++;
              }
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.play_circle_outline_rounded),
              selectedIcon: Icon(Icons.play_circle_fill_rounded),
              label: '오늘',
            ),
            NavigationDestination(
              icon: Icon(Icons.queue_music_outlined),
              selectedIcon: Icon(Icons.queue_music_rounded),
              label: '돌아보기',
            ),
            NavigationDestination(
              icon: Icon(Icons.album_outlined),
              selectedIcon: Icon(Icons.album_rounded),
              label: '방문한 곳',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: '설정',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreen(int index) {
    return switch (index) {
      0 => HomeScreen(
        refreshVersion: _refreshVersion,
        entryVersion: _homeEntryVersion,
        onOpenTodayRecords: _openTodayRecords,
        onOpenDayFlow: _openTodayFlow,
        onOpenLatestInsight: _openInsightDetail,
      ),
      1 => HistoryScreen(
        database: widget.dependencies.database,
        refreshVersion: _refreshVersion,
      ),
      2 => PlaceManagementScreen(
        database: widget.dependencies.database,
        refreshVersion: _refreshVersion,
        onPlacesChanged: _refreshAll,
      ),
      3 => SettingsScreen(
        dependencies: widget.dependencies,
        onDataChanged: _refreshAll,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱을 종료할까요?'),
        content: const Text('지금 화면을 닫고 앱을 종료할게요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('계속 사용'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('종료'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _refreshAll() {
    setState(() {
      _refreshVersion++;
    });
  }

  void _openTodayRecords(
    DayActivityPreview preview,
    Future<DayRouteSnapshot> route,
  ) {
    final now = DateTime.now();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DayDetailScreen(
          database: widget.dependencies.database,
          date: now,
          settingsRepository: widget.dependencies.settingsRepository,
          appBarTitle: '오늘 기록',
          title: '오늘 기록',
          body: '오늘 기기 안에 쌓이고 있는 위치 기록과 머문 곳을 확인해요.',
          initialPreview: preview,
          initialRoute: route,
        ),
      ),
    );
  }

  void _openTodayFlow(
    DayActivityPreview preview,
    Future<DayRouteSnapshot> route,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DayFlowPlaybackScreen(
          database: widget.dependencies.database,
          date: DateTime.now(),
          settingsRepository: widget.dependencies.settingsRepository,
          initialPreview: preview,
          initialRoute: route,
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
          settingsRepository: widget.dependencies.settingsRepository,
          title: insight.title,
          body: insight.body,
        ),
      ),
    );
  }
}

class _ShellHeader extends StatefulWidget {
  const _ShellHeader({
    required this.dependencies,
    required this.refreshVersion,
  });

  final AppDependencies dependencies;
  final int refreshVersion;

  @override
  State<_ShellHeader> createState() => _ShellHeaderState();
}

class _ShellHeaderState extends State<_ShellHeader> {
  late Future<_ShellHeaderSnapshot> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = _load();
  }

  @override
  void didUpdateWidget(covariant _ShellHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion) {
      setState(() {
        _snapshot = _load();
      });
    }
  }

  Future<_ShellHeaderSnapshot> _load() async {
    final settings = await widget.dependencies.settingsRepository.load();
    final isTracking = await widget.dependencies.trackingService.isTracking();
    return _ShellHeaderSnapshot(
      isRecording: settings.trackingEnabled || isTracking,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ShellHeaderSnapshot>(
      future: _snapshot,
      builder: (context, snapshot) {
        final isRecording = snapshot.data?.isRecording ?? false;
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 4),
          child: Row(
            children: [
              const Expanded(child: SizedBox(height: 28)),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isRecording
                              ? AppColors.blueGrey
                              : AppColors.muted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isRecording ? '기록 중' : '기록 쉼',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShellHeaderSnapshot {
  const _ShellHeaderSnapshot({required this.isRecording});

  final bool isRecording;
}
