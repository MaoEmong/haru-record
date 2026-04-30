// ignore_for_file: depend_on_referenced_packages

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('restarts native tracking when saved setting is enabled', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final settingsRepository = SettingsRepository();
    final trackingService = _FakeTrackingService();
    await settingsRepository.save(
      AppSettings.defaults().copyWith(trackingEnabled: true),
    );
    final dependencies = _dependencies(
      database,
      settingsRepository: settingsRepository,
      trackingService: trackingService,
    );

    await dependencies.reconcileTrackingState();

    expect(trackingService.startCount, 1);
  });

  test('does not restart native tracking when it is already running', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final settingsRepository = SettingsRepository();
    final trackingService = _FakeTrackingService(started: true);
    await settingsRepository.save(
      AppSettings.defaults().copyWith(trackingEnabled: true),
    );
    final dependencies = _dependencies(
      database,
      settingsRepository: settingsRepository,
      trackingService: trackingService,
    );

    await dependencies.reconcileTrackingState();

    expect(trackingService.startCount, 0);
  });

  test(
    'startup sync processes yesterday records when summary is missing',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      var importCount = 0;
      var dailyProcessingCount = 0;
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: DateTime(2026, 4, 29, 10),
              latitude: 37,
              longitude: 127,
              accuracy: 20,
            ),
          );
      final dependencies = _dependencies(
        database,
        settingsRepository: SettingsRepository(),
        trackingService: _FakeTrackingService(),
        importPendingEvents: () async {
          importCount++;
          return const LocationEventImportResult(
            importedCount: 0,
            skippedCount: 0,
          );
        },
        runDailyProcessingNow: () async {
          dailyProcessingCount++;
          return const DailyProcessingResult(
            outcome: DailyProcessingOutcome.createdReflection,
            totalPointCount: 1,
            yesterdayPointCount: 1,
            createdReflectionCount: 1,
          );
        },
      );

      final result = await dependencies.syncStartupRecords(
        now: DateTime(2026, 4, 30, 8),
      );

      expect(importCount, 1);
      expect(dailyProcessingCount, 1);
      expect(result.hasChanges, isTrue);
    },
  );

  test(
    'startup sync skips daily processing when yesterday summary exists',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      var dailyProcessingCount = 0;
      await database
          .into(database.dailySummaries)
          .insert(
            DailySummariesCompanion.insert(
              date: '2026-04-29',
              totalDistanceMeters: 0,
              movingMinutes: 0,
              stationaryMinutes: 0,
              visitCount: 0,
              newPlaceCount: 0,
            ),
          );
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: DateTime(2026, 4, 29, 10),
              latitude: 37,
              longitude: 127,
              accuracy: 20,
            ),
          );
      final dependencies = _dependencies(
        database,
        settingsRepository: SettingsRepository(),
        trackingService: _FakeTrackingService(),
        runDailyProcessingNow: () async {
          dailyProcessingCount++;
          return const DailyProcessingResult(
            outcome: DailyProcessingOutcome.createdReflection,
            totalPointCount: 1,
            yesterdayPointCount: 1,
            createdReflectionCount: 1,
          );
        },
      );

      final result = await dependencies.syncStartupRecords(
        now: DateTime(2026, 4, 30, 8),
      );

      expect(dailyProcessingCount, 0);
      expect(result.hasChanges, isFalse);
    },
  );
}

AppDependencies _dependencies(
  AppDatabase database, {
  required SettingsRepository settingsRepository,
  required _FakeTrackingService trackingService,
  Future<LocationEventImportResult> Function()? importPendingEvents,
  Future<DailyProcessingResult> Function()? runDailyProcessingNow,
}) {
  return AppDependencies(
    database: database,
    settingsRepository: settingsRepository,
    trackingService: trackingService,
    notificationService: NotificationService(_FakeNotificationAdapter()),
    permissionService: _FakePermissionService(),
    maintenanceService: AppMaintenanceService(database),
    importPendingEvents:
        importPendingEvents ??
        () async =>
            const LocationEventImportResult(importedCount: 0, skippedCount: 0),
    runDailyProcessingOverride: runDailyProcessingNow,
  );
}

class _FakeTrackingService implements LocationTrackingService {
  _FakeTrackingService({this.started = false});

  bool started;
  int startCount = 0;

  @override
  Future<bool> isTracking() async => started;

  @override
  Future<void> startTracking(AppSettings settings) async {
    startCount++;
    started = true;
  }

  @override
  Future<void> stopTracking() async {
    started = false;
  }
}

class _FakePermissionService implements AppPermissionService {
  @override
  Future<bool> ensureLocationTrackingPermission() async => true;

  @override
  Future<bool> ensureNotificationPermission() async => true;
}

class _FakeNotificationAdapter implements NotificationAdapter {
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
