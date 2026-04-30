import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/app_dependencies.dart';
import 'app/app_theme.dart';
import 'core/config/env_config.dart';
import 'core/time/local_timezone.dart';
import 'features/background/daily_insight_worker.dart';

typedef AppDependenciesLoader = Future<AppDependencies> Function();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(StartupApp(loadDependencies: _loadProductionDependencies));
}

Future<AppDependencies> _loadProductionDependencies() async {
  await EnvConfig.load();
  await lockAppOrientation();
  await configureLocalTimezone();
  final dependencies = await AppDependencies.production();
  unawaited(_finishStartupWork(dependencies));
  return dependencies;
}

class StartupApp extends StatefulWidget {
  const StartupApp({
    super.key,
    required this.loadDependencies,
    this.minimumDuration = const Duration(seconds: 2),
  });

  final AppDependenciesLoader loadDependencies;
  final Duration minimumDuration;

  @override
  State<StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<StartupApp> {
  late final Future<AppDependencies> _dependencies = _load();

  Future<AppDependencies> _load() async {
    final minimumDelay = Future<void>.delayed(widget.minimumDuration);
    final dependencies = await widget.loadDependencies();
    await minimumDelay;
    return dependencies;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppDependencies>(
      future: _dependencies,
      builder: (context, snapshot) {
        final dependencies = snapshot.data;
        if (dependencies != null) {
          return DailyPatternApp(dependencies: dependencies);
        }
        return const StartupSplashPage();
      },
    );
  }
}

class StartupSplashPage extends StatelessWidget {
  const StartupSplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '하루 기록',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.mpBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.mpAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StartupDisc(),
                SizedBox(height: 24),
                Text(
                  'Now Playing',
                  style: TextStyle(
                    color: AppColors.mpText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '오늘의 기록을 준비하고 있어요',
                  style: TextStyle(
                    color: AppColors.mpTextSub,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupDisc extends StatelessWidget {
  const _StartupDisc();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.mpSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.mpBorder),
            ),
            child: const SizedBox.expand(),
          ),
          const SizedBox(
            width: 88,
            height: 88,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.mpAccent,
              backgroundColor: AppColors.mpBorder,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.mpAccent,
              shape: BoxShape.circle,
            ),
            child: SizedBox(width: 18, height: 18),
          ),
        ],
      ),
    );
  }
}

Future<void> _finishStartupWork(AppDependencies dependencies) async {
  await Future<void>.delayed(const Duration(milliseconds: 700));
  try {
    await dependencies.reconcileTrackingState();
    await initializeDailyInsightWorker();
  } catch (_) {
    // Startup background work is retried by user actions or the next launch.
  }
}

Future<void> lockAppOrientation() {
  return SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
}
