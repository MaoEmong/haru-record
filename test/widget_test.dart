// ignore_for_file: depend_on_referenced_packages

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/app/app.dart';
import 'package:projectapp_1/app/app_dependencies.dart';
import 'package:projectapp_1/features/notifications/notification_service.dart';
import 'package:projectapp_1/features/settings/settings_models.dart';
import 'package:projectapp_1/features/settings/settings_repository.dart';
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
}

AppDependencies _testDependencies(
  AppDatabase database, {
  _FakeTrackingService? trackingService,
}) {
  final notificationAdapter = _FakeNotificationAdapter();
  return AppDependencies(
    database: database,
    settingsRepository: SettingsRepository(),
    trackingService: trackingService ?? _FakeTrackingService(),
    notificationService: NotificationService(notificationAdapter),
    importPendingEvents: () async =>
        const LocationEventImportResult(importedCount: 0, skippedCount: 0),
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
