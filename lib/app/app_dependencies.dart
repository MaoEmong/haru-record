import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;

import 'daily_processing_service.dart';
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
import 'startup_record_sync_service.dart';
import 'tracking_reconciliation_service.dart';
import 'tracking_settings_service.dart';

class AppDependencies {
  AppDependencies({
    required this.database,
    required this.settingsRepository,
    required this.trackingService,
    required this.notificationService,
    required this.permissionService,
    required this.maintenanceService,
    required this.importPendingEvents,
    this.runDailyProcessingOverride,
    DailyProcessingService? dailyProcessingService,
    StartupRecordSyncService? startupRecordSyncService,
    TrackingReconciliationService? trackingReconciliationService,
    TrackingSettingsService? trackingSettingsService,
  }) : dailyProcessingService =
           dailyProcessingService ??
           DailyProcessingService(
             database: database,
             settingsRepository: settingsRepository,
             notificationService: notificationService,
             importPendingEvents: importPendingEvents,
             runDailyProcessingOverride: runDailyProcessingOverride,
           ),
       trackingReconciliationService =
           trackingReconciliationService ??
           TrackingReconciliationService(
             settingsRepository: settingsRepository,
             trackingService: trackingService,
           ),
       trackingSettingsService =
           trackingSettingsService ??
           TrackingSettingsService(
             settingsRepository: settingsRepository,
             trackingService: trackingService,
           ) {
    this.startupRecordSyncService =
        startupRecordSyncService ??
        StartupRecordSyncService(
          database: database,
          dailyProcessingService: this.dailyProcessingService,
          importPendingEvents: importPendingEvents,
        );
  }

  final AppDatabase database;
  final SettingsRepository settingsRepository;
  final LocationTrackingService trackingService;
  final NotificationService notificationService;
  final AppPermissionService permissionService;
  final AppMaintenanceService maintenanceService;
  final Future<LocationEventImportResult> Function() importPendingEvents;
  final Future<DailyProcessingResult> Function()? runDailyProcessingOverride;
  final DailyProcessingService dailyProcessingService;
  late final StartupRecordSyncService startupRecordSyncService;
  final TrackingReconciliationService trackingReconciliationService;
  final TrackingSettingsService trackingSettingsService;

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
    return startupRecordSyncService.sync(now: now);
  }

  Future<DailyProcessingResult> runDailyProcessingNow({DateTime? now}) async {
    return dailyProcessingService.run(now: now);
  }

  Future<void> reconcileTrackingState() async {
    return trackingReconciliationService.reconcile();
  }

  Future<void> saveTrackingEnabled({
    required AppSettings settings,
    required bool enabled,
  }) async {
    return trackingSettingsService.saveTrackingEnabled(
      settings: settings,
      enabled: enabled,
    );
  }
}
