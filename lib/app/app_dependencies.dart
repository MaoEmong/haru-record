import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;

import '../features/background/daily_insight_worker.dart';
import '../features/notifications/notification_service.dart';
import '../features/permissions/app_permission_service.dart';
import '../features/settings/settings_models.dart';
import '../features/settings/settings_repository.dart';
import '../features/storage/app_maintenance_service.dart';
import '../features/storage/app_database.dart';
import '../features/storage/database_factory.dart';
import '../features/tracking/location_event_importer.dart';
import '../features/tracking/location_tracking_service.dart';
import '../features/tracking/platform_location_tracking_service.dart';

class AppDependencies {
  const AppDependencies({
    required this.database,
    required this.settingsRepository,
    required this.trackingService,
    required this.notificationService,
    required this.permissionService,
    required this.maintenanceService,
    required this.importPendingEvents,
    this.runDailyProcessingOverride,
  });

  final AppDatabase database;
  final SettingsRepository settingsRepository;
  final LocationTrackingService trackingService;
  final NotificationService notificationService;
  final AppPermissionService permissionService;
  final AppMaintenanceService maintenanceService;
  final Future<LocationEventImportResult> Function() importPendingEvents;
  final Future<DailyProcessingResult> Function()? runDailyProcessingOverride;

  static Future<AppDependencies> production() async {
    final database = AppDatabase(openAppDatabaseConnection());
    final notificationAdapter = FlutterLocalNotificationAdapter(
      location: tz.local,
    );

    return AppDependencies(
      database: database,
      settingsRepository: SettingsRepository(),
      trackingService: PlatformLocationTrackingService(),
      notificationService: NotificationService(notificationAdapter),
      permissionService: const PermissionHandlerAppPermissionService(),
      maintenanceService: AppMaintenanceService(database),
      importPendingEvents: () async {
        final eventDirectory = await getApplicationSupportDirectory();
        final importer = LocationEventImporter.fromFile(
          database,
          File(path.join(eventDirectory.path, 'location_events.jsonl')),
        );
        return importer.importPendingEvents();
      },
    );
  }

  Future<StartupRecordSyncResult> syncStartupRecords({DateTime? now}) async {
    final importResult = await importPendingEvents();
    final effectiveNow = now ?? DateTime.now();
    DailyProcessingResult? dailyProcessingResult;
    if (await _hasUnprocessedYesterdayRecords(effectiveNow)) {
      dailyProcessingResult = await runDailyProcessingNow(now: effectiveNow);
    }
    return StartupRecordSyncResult(
      importResult: importResult,
      dailyProcessingResult: dailyProcessingResult,
    );
  }

  Future<DailyProcessingResult> runDailyProcessingNow({DateTime? now}) async {
    if (runDailyProcessingOverride != null) {
      return await runDailyProcessingOverride!();
    }
    final settings = await settingsRepository.load();
    final processor = DailyInsightProcessor(
      database: database,
      notificationService: notificationService,
      importPendingEvents: importPendingEvents,
      settings: settings,
    );
    return await processor.run(now: now ?? DateTime.now());
  }

  Future<bool> _hasUnprocessedYesterdayRecords(DateTime now) async {
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final dateKey = _dateKey(yesterdayStart);

    final existingSummary =
        await (database.select(database.dailySummaries)
              ..where((summary) => summary.date.equals(dateKey))
              ..limit(1))
            .getSingleOrNull();
    if (existingSummary != null) return false;

    final yesterdayPoint =
        await (database.select(database.locationPoints)
              ..where(
                (point) =>
                    point.timestamp.isBiggerOrEqualValue(yesterdayStart) &
                    point.timestamp.isSmallerThanValue(todayStart),
              )
              ..limit(1))
            .getSingleOrNull();
    return yesterdayPoint != null;
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> reconcileTrackingState() async {
    final settings = await settingsRepository.load();
    if (!settings.trackingEnabled) return;
    if (await trackingService.isTracking()) return;
    await trackingService.startTracking(settings);
  }

  Future<void> saveTrackingEnabled({
    required AppSettings settings,
    required bool enabled,
  }) async {
    final updated = settings.copyWith(trackingEnabled: enabled);
    if (enabled) {
      await trackingService.startTracking(updated);
    } else {
      await trackingService.stopTracking();
    }
    await settingsRepository.save(updated);
  }
}

class StartupRecordSyncResult {
  const StartupRecordSyncResult({
    required this.importResult,
    required this.dailyProcessingResult,
  });

  final LocationEventImportResult importResult;
  final DailyProcessingResult? dailyProcessingResult;

  bool get hasChanges {
    if (importResult.importedCount > 0) return true;
    return switch (dailyProcessingResult?.outcome) {
      DailyProcessingOutcome.createdReflection ||
      DailyProcessingOutcome.noHighlights => true,
      _ => false,
    };
  }
}
