// ignore_for_file: depend_on_referenced_packages

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/app/app.dart';
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

  testWidgets('shows the daily pattern app shell', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daily Pattern'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Places'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('No insights yet'), findsOneWidget);
  });

  testWidgets('settings screen saves tracking state', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    final trackingService = _FakeTrackingService();
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: _testDependencies(
          database,
          trackingService: trackingService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tracking-switch')));
    await tester.pumpAndSettle();

    expect(trackingService.started, isTrue);
    expect(find.text('Tracking active'), findsOneWidget);
  });

  testWidgets('settings screen edits thresholds and notification time', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('movement-threshold-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('number-setting-field')),
      '250',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stay-threshold-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('number-setting-field')),
      '20',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('retention-days-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('number-setting-field')),
      '14',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('notification-time-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('hour-setting-field')),
      '8',
    );
    await tester.enterText(
      find.byKey(const ValueKey('minute-setting-field')),
      '30',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('250 m'), findsOneWidget);
    expect(find.text('20 min'), findsOneWidget);
    expect(find.text('14 days'), findsOneWidget);
    expect(find.text('08:30'), findsOneWidget);
  });

  testWidgets('tracking toggle explains missing location permission', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final trackingService = _FakeTrackingService();
    final permissionService = _FakePermissionService(locationGranted: false);
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: _testDependencies(
          database,
          trackingService: trackingService,
          permissionService: permissionService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tracking-switch')));
    await tester.pumpAndSettle();

    expect(permissionService.requestedLocation, isTrue);
    expect(trackingService.started, isFalse);
    expect(find.text('Location permission is required'), findsOneWidget);
  });

  testWidgets('manual daily processing refreshes visible insight state', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    var processingRuns = 0;
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: _testDependencies(
          database,
          runDailyProcessingNow: () async {
            processingRuns++;
            await database.into(database.insights).insert(
                  InsightsCompanion.insert(
                    date: DateTime(2026, 4, 27),
                    type: 'movementChange',
                    severity: 'notable',
                    title: 'Movement was lower than usual',
                    body: 'Yesterday was quieter than your recent average.',
                    evidence: '100m vs 400m recent average',
                    createdAt: DateTime(2026, 4, 27, 9),
                  ),
                );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No insights yet'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run daily processing now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(processingRuns, 1);
    expect(find.text('Movement was lower than usual'), findsOneWidget);
  });

  testWidgets('settings cleanup removes raw points but keeps insights', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.into(database.locationPoints).insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 1, 1),
            latitude: 37,
            longitude: 127,
            accuracy: 20,
          ),
        );
    await database.into(database.insights).insert(
          InsightsCompanion.insert(
            date: DateTime(2026, 4, 27),
            type: 'movementChange',
            severity: 'notable',
            title: 'Existing insight',
            body: 'Kept after raw cleanup.',
            evidence: 'seed data',
            createdAt: DateTime(2026, 4, 27),
          ),
        );

    await tester.pumpWidget(
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Delete raw location points'),
      200,
    );
    await tester.tap(find.text('Delete raw location points'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    final points = await database.select(database.locationPoints).get();
    final insights = await database.select(database.insights).get();
    expect(points, isEmpty);
    expect(insights, hasLength(1));
    expect(find.text('Raw location points deleted'), findsOneWidget);
  });
}

AppDependencies _testDependencies(
  AppDatabase database, {
  _FakeTrackingService? trackingService,
  _FakePermissionService? permissionService,
  Future<void> Function()? runDailyProcessingNow,
}) {
  final notificationAdapter = _FakeNotificationAdapter();
  return AppDependencies(
    database: database,
    settingsRepository: SettingsRepository(),
    trackingService: trackingService ?? _FakeTrackingService(),
    notificationService: NotificationService(notificationAdapter),
    permissionService:
        permissionService ?? _FakePermissionService(locationGranted: true),
    maintenanceService: AppMaintenanceService(database),
    importPendingEvents: () async =>
        const LocationEventImportResult(importedCount: 0, skippedCount: 0),
    runDailyProcessingOverride: runDailyProcessingNow,
  );
}

class _FakeTrackingService implements LocationTrackingService {
  bool started = false;

  @override
  Future<bool> isTracking() async => started;

  @override
  Future<void> startTracking(AppSettings settings) async {
    started = true;
  }

  @override
  Future<void> stopTracking() async {
    started = false;
  }
}

class _FakePermissionService implements AppPermissionService {
  _FakePermissionService({required this.locationGranted});

  bool locationGranted;
  bool requestedLocation = false;

  @override
  Future<bool> ensureLocationTrackingPermission() async {
    requestedLocation = true;
    return locationGranted;
  }

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
