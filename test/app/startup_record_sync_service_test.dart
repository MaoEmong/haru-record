// ignore_for_file: depend_on_referenced_packages

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/background/daily_insight_worker.dart';
import 'package:projectapp_1/features/settings/settings_repository.dart';
import 'package:projectapp_1/features/storage/app_database.dart';
import 'package:projectapp_1/features/tracking/location_event_importer.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../helpers/test_app_dependencies.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
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
      final dependencies = testDependencies(
        database,
        settingsRepository: SettingsRepository(),
        trackingService: FakeTrackingService(),
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
      final dependencies = testDependencies(
        database,
        settingsRepository: SettingsRepository(),
        trackingService: FakeTrackingService(),
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
