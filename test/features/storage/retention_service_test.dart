import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/storage/app_database.dart';
import 'package:projectapp_1/features/storage/retention_service.dart';

void main() {
  late AppDatabase database;
  late RetentionService service;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    service = RetentionService(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('deletes old raw points but keeps summaries and insights', () async {
    final now = DateTime(2026, 4, 26, 9);
    final olderThanRetention = now.subtract(const Duration(days: 31));
    final withinRetention = now.subtract(const Duration(days: 1));

    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: olderThanRetention,
            latitude: 37.1,
            longitude: 127.1,
            accuracy: 20,
          ),
        );
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: withinRetention,
            latitude: 37.2,
            longitude: 127.2,
            accuracy: 20,
          ),
        );
    await database
        .into(database.dailySummaries)
        .insert(
          DailySummariesCompanion.insert(
            date: '2026-04-25',
            totalDistanceMeters: 1000,
            movingMinutes: 30,
            stationaryMinutes: 600,
            visitCount: 2,
            newPlaceCount: 0,
          ),
        );
    await database
        .into(database.insights)
        .insert(
          InsightsCompanion.insert(
            date: DateTime(2026, 4, 25),
            type: 'movementChange',
            severity: 'notable',
            title: 'Movement was lower than usual',
            body: 'Yesterday was quieter than your recent average.',
            evidence: '{"movingMinutes":30}',
            createdAt: now,
          ),
        );

    final deleted = await service.deleteRawPointsOlderThan(
      now,
      retentionDays: 30,
    );

    final points = await database.select(database.locationPoints).get();
    final summaries = await database.select(database.dailySummaries).get();
    final insights = await database.select(database.insights).get();
    expect(deleted, 1);
    expect(points, hasLength(1));
    expect(points.single.timestamp, withinRetention);
    expect(summaries, hasLength(1));
    expect(insights, hasLength(1));
  });
}
