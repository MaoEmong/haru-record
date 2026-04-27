import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/app_dependencies.dart';
import 'core/config/env_config.dart';
import 'core/time/local_timezone.dart';
import 'features/background/daily_insight_worker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  await lockAppOrientation();
  await configureLocalTimezone();
  final dependencies = await AppDependencies.production();
  await dependencies.reconcileTrackingState();
  await initializeDailyInsightWorker();
  runApp(DailyPatternApp(dependencies: dependencies));
}

Future<void> lockAppOrientation() {
  return SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
}
