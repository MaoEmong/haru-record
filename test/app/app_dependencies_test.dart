// ignore_for_file: depend_on_referenced_packages

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/app/app_dependencies.dart';
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
}

AppDependencies _dependencies(
  AppDatabase database, {
  required SettingsRepository settingsRepository,
  required _FakeTrackingService trackingService,
}) {
  return AppDependencies(
    database: database,
    settingsRepository: settingsRepository,
    trackingService: trackingService,
    notificationService: NotificationService(_FakeNotificationAdapter()),
    permissionService: _FakePermissionService(),
    maintenanceService: AppMaintenanceService(database),
    importPendingEvents: () async =>
        const LocationEventImportResult(importedCount: 0, skippedCount: 0),
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
