import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/storage/app_database.dart';
import 'package:projectapp_1/features/timeline/day_route_repository.dart';

void main() {
  test('returns ordered route points and visits for a day', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final date = DateTime(2026, 4, 26);
    final placeId = await database
        .into(database.placeClusters)
        .insert(
          PlaceClustersCompanion.insert(
            centerLatitude: 37.1,
            centerLongitude: 127.1,
            radiusMeters: 100,
            displayName: const Value('카페'),
            createdAt: date,
            updatedAt: date,
            visitCount: 1,
          ),
        );
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 26, 9, 10),
            latitude: 37.0,
            longitude: 127.0,
            accuracy: 20,
          ),
        );
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 26, 9),
            latitude: 36.9,
            longitude: 126.9,
            accuracy: 20,
          ),
        );
    await database
        .into(database.visits)
        .insert(
          VisitsCompanion.insert(
            placeClusterId: Value(placeId),
            startedAt: DateTime(2026, 4, 26, 10),
            endedAt: DateTime(2026, 4, 26, 11),
            durationMinutes: 60,
            representativeLatitude: 37.1,
            representativeLongitude: 127.1,
          ),
        );

    final route = await DayRouteRepository(database).loadForDate(date);

    expect(route.points.map((point) => point.timeLabel), ['09:00', '09:10']);
    expect(route.visits.single.placeLabel, '카페');
  });
}
