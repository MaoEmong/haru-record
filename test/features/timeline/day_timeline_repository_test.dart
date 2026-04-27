import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/storage/app_database.dart';
import 'package:projectapp_1/features/timeline/day_timeline_repository.dart';

void main() {
  test('returns visits ordered by start time with place labels', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final placeId = await database
        .into(database.placeClusters)
        .insert(
          PlaceClustersCompanion.insert(
            centerLatitude: 37,
            centerLongitude: 127,
            radiusMeters: 100,
            displayName: const Value('집 근처'),
            createdAt: DateTime(2026, 4, 26),
            updatedAt: DateTime(2026, 4, 26),
            visitCount: 1,
          ),
        );
    await database
        .into(database.visits)
        .insert(
          VisitsCompanion.insert(
            startedAt: DateTime(2026, 4, 26, 13),
            endedAt: DateTime(2026, 4, 26, 13, 25),
            durationMinutes: 25,
            representativeLatitude: 37.1,
            representativeLongitude: 127.1,
          ),
        );
    await database
        .into(database.visits)
        .insert(
          VisitsCompanion.insert(
            placeClusterId: Value(placeId),
            startedAt: DateTime(2026, 4, 26, 9),
            endedAt: DateTime(2026, 4, 26, 10),
            durationMinutes: 60,
            representativeLatitude: 37,
            representativeLongitude: 127,
          ),
        );
    await database
        .into(database.visits)
        .insert(
          VisitsCompanion.insert(
            placeClusterId: Value(placeId),
            startedAt: DateTime(2026, 4, 27, 9),
            endedAt: DateTime(2026, 4, 27, 10),
            durationMinutes: 60,
            representativeLatitude: 37,
            representativeLongitude: 127,
          ),
        );

    final repository = DayTimelineRepository(database);
    final items = await repository.loadForDate(DateTime(2026, 4, 26));

    expect(items, hasLength(2));
    expect(items.first.timeLabel, '09:00');
    expect(items.first.placeLabel, '집 근처');
    expect(items.first.durationLabel, '1시간 머문 곳');
    expect(items.last.timeLabel, '13:00');
    expect(items.last.placeLabel, '방문한 곳');
    expect(items.last.durationLabel, '25분 머문 곳');
  });
}
