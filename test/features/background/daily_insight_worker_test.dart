import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/background/daily_insight_worker.dart';
import 'package:projectapp_1/features/notifications/notification_service.dart';
import 'package:projectapp_1/features/settings/settings_models.dart';
import 'package:projectapp_1/features/storage/app_database.dart';
import 'package:projectapp_1/features/tracking/location_event_importer.dart';

void main() {
  test('registers daily insight worker as a periodic task', () async {
    final scheduler = FakeDailyWorkerScheduler();

    await initializeDailyInsightWorker(scheduler: scheduler);

    expect(scheduler.initialized, isTrue);
    expect(scheduler.uniqueName, dailyInsightWorkerName);
    expect(scheduler.taskName, dailyInsightWorkerName);
    expect(scheduler.frequency, const Duration(hours: 24));
  });

  test(
    'processes imported location points into insights and notification',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final notificationAdapter = FakeNotificationAdapter();
      final processor = DailyInsightProcessor(
        database: database,
        notificationService: NotificationService(notificationAdapter),
        importPendingEvents: () async =>
            const LocationEventImportResult(importedCount: 0, skippedCount: 0),
        settings: AppSettings.defaults(),
      );
      final now = DateTime(2026, 4, 26, 9);

      await database
          .into(database.dailySummaries)
          .insert(
            DailySummariesCompanion.insert(
              date: '2026-04-24',
              totalDistanceMeters: 2000,
              movingMinutes: 45,
              stationaryMinutes: 600,
              visitCount: 3,
              newPlaceCount: 0,
            ),
          );
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: DateTime(2026, 4, 25, 10),
              latitude: 37.5665,
              longitude: 126.9780,
              accuracy: 20,
            ),
          );
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: DateTime(2026, 4, 25, 10, 11),
              latitude: 37.5666,
              longitude: 126.9781,
              accuracy: 20,
            ),
          );
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: DateTime(2026, 3, 1),
              latitude: 37,
              longitude: 127,
              accuracy: 20,
            ),
          );

      final result = await processor.run(now: now);

      final visits = await database.select(database.visits).get();
      final places = await database.select(database.placeClusters).get();
      final summaries = await database.select(database.dailySummaries).get();
      final insights = await database.select(database.insights).get();
      final points = await database.select(database.locationPoints).get();
      expect(visits, hasLength(1));
      expect(places, hasLength(1));
      expect(visits.single.placeClusterId, places.single.id);
      expect(places.single.visitCount, 1);
      expect(
        summaries.where((summary) => summary.date == '2026-04-25'),
        hasLength(1),
      );
      expect(
        summaries.singleWhere((summary) => summary.date == '2026-04-25')
            .newPlaceCount,
        1,
      );
      expect(insights, isNotEmpty);
      expect(result.outcome, DailyProcessingOutcome.createdReflection);
      expect(result.yesterdayPointCount, 2);
      expect(result.createdReflectionCount, 2);
      expect(notificationAdapter.scheduledHour, 9);
      expect(
        points.every((point) => point.timestamp.isAfter(DateTime(2026, 3, 1))),
        isTrue,
      );

      await database.close();
    },
  );

  test('daily processing is idempotent for the same day', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final notificationAdapter = FakeNotificationAdapter();
    final processor = DailyInsightProcessor(
      database: database,
      notificationService: NotificationService(notificationAdapter),
      importPendingEvents: () async =>
          const LocationEventImportResult(importedCount: 0, skippedCount: 0),
      settings: AppSettings.defaults(),
    );
    final now = DateTime(2026, 4, 26, 9);

    await database
        .into(database.dailySummaries)
        .insert(
          DailySummariesCompanion.insert(
            date: '2026-04-24',
            totalDistanceMeters: 2000,
            movingMinutes: 45,
            stationaryMinutes: 600,
            visitCount: 3,
            newPlaceCount: 0,
          ),
        );
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 25, 10),
            latitude: 37.5665,
            longitude: 126.9780,
            accuracy: 20,
          ),
        );
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 25, 10, 11),
            latitude: 37.5666,
            longitude: 126.9781,
            accuracy: 20,
          ),
        );

    await processor.run(now: now);
    await processor.run(now: now);

    final visits = await database.select(database.visits).get();
    final places = await database.select(database.placeClusters).get();
    final summaries = await database.select(database.dailySummaries).get();
    final insights = await database.select(database.insights).get();
    expect(visits, hasLength(1));
    expect(places, hasLength(1));
    expect(visits.single.placeClusterId, places.single.id);
    expect(places.single.visitCount, 1);
    expect(
      summaries.where((summary) => summary.date == '2026-04-25'),
      hasLength(1),
    );
    expect(insights, hasLength(2));

    await database.close();
  });

  test('cancels daily notification when notifications are disabled', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final notificationAdapter = FakeNotificationAdapter();
    final processor = DailyInsightProcessor(
      database: database,
      notificationService: NotificationService(notificationAdapter),
      importPendingEvents: () async =>
          const LocationEventImportResult(importedCount: 0, skippedCount: 0),
      settings: AppSettings.defaults().copyWith(notificationEnabled: false),
    );

    await processor.run(now: DateTime(2026, 4, 26, 9));

    expect(notificationAdapter.scheduledHour, isNull);
    expect(
      notificationAdapter.cancelledId,
      NotificationService.dailyInsightNotificationId,
    );

    await database.close();
  });

  test('reports when there are no raw records to summarize', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final notificationAdapter = FakeNotificationAdapter();
    final processor = DailyInsightProcessor(
      database: database,
      notificationService: NotificationService(notificationAdapter),
      importPendingEvents: () async =>
          const LocationEventImportResult(importedCount: 0, skippedCount: 0),
      settings: AppSettings.defaults(),
    );

    final result = await processor.run(now: DateTime(2026, 4, 26, 9));

    expect(result.outcome, DailyProcessingOutcome.noRawRecords);
    expect(result.totalPointCount, 0);
    expect(result.yesterdayPointCount, 0);

    await database.close();
  });

  test('reports when raw records exist but not for yesterday', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final notificationAdapter = FakeNotificationAdapter();
    final processor = DailyInsightProcessor(
      database: database,
      notificationService: NotificationService(notificationAdapter),
      importPendingEvents: () async =>
          const LocationEventImportResult(importedCount: 0, skippedCount: 0),
      settings: AppSettings.defaults(),
    );
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 20, 10),
            latitude: 37,
            longitude: 127,
            accuracy: 20,
          ),
        );

    final result = await processor.run(now: DateTime(2026, 4, 26, 9));

    expect(result.outcome, DailyProcessingOutcome.noYesterdayRecords);
    expect(result.totalPointCount, 1);
    expect(result.yesterdayPointCount, 0);

    await database.close();
  });

  test('reports when yesterday records produce no reflection', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final notificationAdapter = FakeNotificationAdapter();
    final processor = DailyInsightProcessor(
      database: database,
      notificationService: NotificationService(notificationAdapter),
      importPendingEvents: () async =>
          const LocationEventImportResult(importedCount: 0, skippedCount: 0),
      settings: AppSettings.defaults(),
    );
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 25, 10),
            latitude: 37,
            longitude: 127,
            accuracy: 20,
          ),
        );

    final result = await processor.run(now: DateTime(2026, 4, 26, 9));

    expect(result.outcome, DailyProcessingOutcome.noHighlights);
    expect(result.totalPointCount, 1);
    expect(result.yesterdayPointCount, 1);
    expect(result.createdReflectionCount, 0);

    await database.close();
  });
}

class FakeDailyWorkerScheduler implements DailyWorkerScheduler {
  bool initialized = false;
  String? uniqueName;
  String? taskName;
  Duration? frequency;

  @override
  Future<void> initialize(void Function() dispatcher) async {
    initialized = true;
  }

  @override
  Future<void> registerPeriodicTask({
    required String uniqueName,
    required String taskName,
    required Duration frequency,
  }) async {
    this.uniqueName = uniqueName;
    this.taskName = taskName;
    this.frequency = frequency;
  }
}

class FakeNotificationAdapter implements NotificationAdapter {
  int? scheduledHour;
  int? cancelledId;

  @override
  Future<bool?> requestPermission() async => true;

  @override
  Future<void> cancel(int id) async {
    cancelledId = id;
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    scheduledHour = hour;
  }
}
