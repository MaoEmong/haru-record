import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/settings/settings_models.dart';
import 'package:projectapp_1/features/storage/app_database.dart';
import 'package:projectapp_1/features/timeline/day_activity_preview_repository.dart';

void main() {
  test(
    'infers current-day visits from raw points using saved thresholds',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final date = DateTime(2026, 4, 28);
      final start = DateTime(2026, 4, 28, 9);

      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: start,
              latitude: 35.1596,
              longitude: 129.0602,
              accuracy: 20,
            ),
          );
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: start.add(const Duration(minutes: 6)),
              latitude: 35.15961,
              longitude: 129.06021,
              accuracy: 20,
            ),
          );

      final preview = await DayActivityPreviewRepository(database).loadForDate(
        date,
        settings: AppSettings.defaults().copyWith(
          minimumMovementMeters: 50,
          minimumStayMinutes: 5,
        ),
      );

      expect(preview.visitCount, 1);
      expect(preview.timeline, hasLength(1));
      expect(preview.timeline.single.placeLabel, '머문 곳');
      expect(preview.timeline.single.durationLabel, '머문 곳으로 보여요');
    },
  );

  test(
    'shows inferred stays even when an earlier persisted visit exists',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final date = DateTime(2026, 4, 28);
      final persistedPlaceId = await database
          .into(database.placeClusters)
          .insert(
            PlaceClustersCompanion.insert(
              centerLatitude: 35.1596,
              centerLongitude: 129.0602,
              radiusMeters: 50,
              displayName: const Value('학원'),
              createdAt: date,
              updatedAt: date,
              visitCount: 1,
            ),
          );
      await database
          .into(database.visits)
          .insert(
            VisitsCompanion.insert(
              placeClusterId: Value(persistedPlaceId),
              startedAt: DateTime(2026, 4, 28, 8, 20),
              endedAt: DateTime(2026, 4, 28, 9, 20),
              durationMinutes: 60,
              representativeLatitude: 35.1596,
              representativeLongitude: 129.0602,
            ),
          );

      for (final (minute, latitude, longitude) in [
        (0, 35.1611000, 129.0620000),
        (13, 35.1611200, 129.0620200),
        (18, 35.1610800, 129.0619900),
      ]) {
        await database
            .into(database.locationPoints)
            .insert(
              LocationPointsCompanion.insert(
                timestamp: DateTime(
                  2026,
                  4,
                  28,
                  12,
                  41,
                ).add(Duration(minutes: minute)),
                latitude: latitude,
                longitude: longitude,
                accuracy: 12,
              ),
            );
      }

      final preview = await DayActivityPreviewRepository(database).loadForDate(
        date,
        settings: AppSettings.defaults().copyWith(
          minimumMovementMeters: 50,
          minimumStayMinutes: 5,
        ),
      );

      expect(preview.visitCount, 2);
      expect(preview.timeline.map((item) => item.placeLabel), ['학원', '머문 곳']);
    },
  );

  test(
    'hides inferred stays that duplicate a persisted place location',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final date = DateTime(2026, 4, 28);
      final placeId = await database
          .into(database.placeClusters)
          .insert(
            PlaceClustersCompanion.insert(
              centerLatitude: 35.1596608,
              centerLongitude: 129.0602568,
              radiusMeters: 50,
              displayName: const Value('학원'),
              createdAt: date,
              updatedAt: date,
              visitCount: 1,
            ),
          );
      await database
          .into(database.visits)
          .insert(
            VisitsCompanion.insert(
              placeClusterId: Value(placeId),
              startedAt: DateTime(2026, 4, 28, 8, 23),
              endedAt: DateTime(2026, 4, 28, 9, 25),
              durationMinutes: 62,
              representativeLatitude: 35.1596608,
              representativeLongitude: 129.0602568,
            ),
          );

      for (final time in [
        DateTime(2026, 4, 28, 9, 58),
        DateTime(2026, 4, 28, 12, 41),
      ]) {
        await database
            .into(database.locationPoints)
            .insert(
              LocationPointsCompanion.insert(
                timestamp: time,
                latitude: 35.1596840,
                longitude: 129.0602311,
                accuracy: 5,
              ),
            );
      }

      final preview = await DayActivityPreviewRepository(database).loadForDate(
        date,
        settings: AppSettings.defaults().copyWith(
          minimumMovementMeters: 50,
          minimumStayMinutes: 5,
        ),
      );

      expect(preview.visitCount, 1);
      expect(preview.timeline, hasLength(1));
      expect(preview.timeline.single.placeLabel, '학원');
    },
  );

  test('estimates distance from cleaned route display points', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final date = DateTime(2026, 4, 28);
    final start = DateTime(2026, 4, 28, 9);

    for (final (index, latitude, longitude) in [
      (0, 35.159682, 129.060232),
      (1, 35.159265, 129.060769),
      (2, 35.159680, 129.060281),
    ]) {
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: start.add(Duration(seconds: index * 10)),
              latitude: latitude,
              longitude: longitude,
              accuracy: 8,
              speed: const Value(0.03),
            ),
          );
    }

    final preview = await DayActivityPreviewRepository(
      database,
    ).loadForDate(date);

    expect(preview.pointCount, 3);
    expect(preview.totalDistanceMeters, lessThan(1));
  });
}
