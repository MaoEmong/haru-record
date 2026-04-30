// ignore_for_file: depend_on_referenced_packages

import 'package:projectapp_1/app/app_dependencies.dart';
import 'package:projectapp_1/features/background/daily_insight_worker.dart';
import 'package:projectapp_1/features/notifications/notification_service.dart';
import 'package:projectapp_1/features/permissions/app_permission_service.dart';
import 'package:projectapp_1/features/settings/settings_models.dart';
import 'package:projectapp_1/features/settings/settings_repository.dart';
import 'package:projectapp_1/features/storage/app_maintenance_service.dart';
import 'package:projectapp_1/features/storage/app_database.dart';
import 'package:projectapp_1/features/tracking/location_event_importer.dart';
import 'package:projectapp_1/features/tracking/location_tracking_service.dart';

AppDependencies testDependencies(
  AppDatabase database, {
  SettingsRepository? settingsRepository,
  FakeTrackingService? trackingService,
  FakePermissionService? permissionService,
  Future<LocationEventImportResult> Function()? importPendingEvents,
  Future<DailyProcessingResult> Function()? runDailyProcessingNow,
}) {
  final notificationAdapter = FakeNotificationAdapter();
  return AppDependencies(
    database: database,
    settingsRepository: settingsRepository ?? SettingsRepository(),
    trackingService: trackingService ?? FakeTrackingService(),
    notificationService: NotificationService(notificationAdapter),
    permissionService:
        permissionService ?? FakePermissionService(locationGranted: true),
    maintenanceService: AppMaintenanceService(database),
    importPendingEvents:
        importPendingEvents ??
        () async =>
            const LocationEventImportResult(importedCount: 0, skippedCount: 0),
    runDailyProcessingOverride: runDailyProcessingNow,
  );
}

class FakeTrackingService implements LocationTrackingService {
  FakeTrackingService({this.started = false});

  bool started;
  int startCount = 0;
  int stopCount = 0;
  AppSettings? lastStartedSettings;

  @override
  Future<bool> isTracking() async => started;

  @override
  Future<void> startTracking(AppSettings settings) async {
    startCount++;
    lastStartedSettings = settings;
    started = true;
  }

  @override
  Future<void> stopTracking() async {
    stopCount++;
    started = false;
  }
}

class FakePermissionService implements AppPermissionService {
  FakePermissionService({
    required this.locationGranted,
    this.notificationGranted = true,
  });

  bool locationGranted;
  bool notificationGranted;
  bool requestedLocation = false;
  bool requestedNotification = false;

  @override
  Future<bool> ensureLocationTrackingPermission() async {
    requestedLocation = true;
    return locationGranted;
  }

  @override
  Future<bool> ensureNotificationPermission() async {
    requestedNotification = true;
    return notificationGranted;
  }
}

class FakeNotificationAdapter implements NotificationAdapter {
  @override
  Future<void> cancel(int id) async {}

  @override
  Future<bool?> requestPermission() async => true;

  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {}
}
