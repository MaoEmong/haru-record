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
    expect(route.points.map((point) => point.timestamp), [
      DateTime(2026, 4, 26, 9),
      DateTime(2026, 4, 26, 9, 10),
    ]);
    expect(route.visits.single.placeLabel, '카페');
  });

  test('clusters nearby jitter into one route display point', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final date = DateTime(2026, 4, 26);

    for (var i = 0; i < 3; i++) {
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: DateTime(2026, 4, 26, 9, i * 5),
              latitude: 37,
              longitude: 127,
              accuracy: 20,
            ),
          );
    }
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 26, 9, 20),
            latitude: 37.01,
            longitude: 127,
            accuracy: 20,
          ),
        );

    final route = await DayRouteRepository(database).loadForDate(date);

    expect(route.rawPointCount, 4);
    expect(route.points.map((point) => point.timeLabel), ['09:00', '09:20']);
  });

  test(
    'excludes low accuracy points from route display but keeps raw count',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final date = DateTime(2026, 4, 26);

      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: DateTime(2026, 4, 26, 9),
              latitude: 37,
              longitude: 127,
              accuracy: 20,
            ),
          );
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: DateTime(2026, 4, 26, 9, 5),
              latitude: 37.5,
              longitude: 127.5,
              accuracy: 120,
            ),
          );
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: DateTime(2026, 4, 26, 9, 10),
              latitude: 37.01,
              longitude: 127.01,
              accuracy: 20,
            ),
          );

      final route = await DayRouteRepository(database).loadForDate(date);

      expect(route.rawPointCount, 3);
      expect(route.points.map((point) => point.timeLabel), ['09:00', '09:10']);
    },
  );

  test('excludes invalid coordinates from route and visit display', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final date = DateTime(2026, 4, 26);

    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 26, 9),
            latitude: 37,
            longitude: 127,
            accuracy: 20,
          ),
        );
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 26, 9, 5),
            latitude: 91,
            longitude: 127,
            accuracy: 20,
          ),
        );
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 26, 9, 10),
            latitude: 37.01,
            longitude: 127.01,
            accuracy: 20,
          ),
        );
    await database
        .into(database.visits)
        .insert(
          VisitsCompanion.insert(
            startedAt: DateTime(2026, 4, 26, 10),
            endedAt: DateTime(2026, 4, 26, 11),
            durationMinutes: 60,
            representativeLatitude: 91,
            representativeLongitude: 127,
          ),
        );

    final route = await DayRouteRepository(database).loadForDate(date);

    expect(route.rawPointCount, 2);
    expect(route.points.map((point) => point.timeLabel), ['09:00', '09:10']);
    expect(route.visits, isEmpty);
  });

  test('collapses low speed gps drift into one route display point', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final date = DateTime(2026, 4, 26);

    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 26, 9),
            latitude: 35.159682,
            longitude: 129.060232,
            accuracy: 4,
            speed: const Value(0.02),
          ),
        );
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 26, 9, 0, 10),
            latitude: 35.159265,
            longitude: 129.060769,
            accuracy: 4,
            speed: const Value(0.03),
          ),
        );
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 26, 9, 0, 20),
            latitude: 35.159680,
            longitude: 129.060281,
            accuracy: 20,
            speed: const Value(0.04),
          ),
        );

    final route = await DayRouteRepository(database).loadForDate(date);

    expect(route.rawPointCount, 3);
    expect(route.points.map((point) => point.timeLabel), ['09:00']);
  });

  test(
    'chooses the center of stationary gps drift instead of the sharpest outlier',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final date = DateTime(2026, 4, 26);

      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: DateTime(2026, 4, 26, 9),
              latitude: 35.159682,
              longitude: 129.060232,
              accuracy: 20,
              speed: const Value(0.02),
            ),
          );
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: DateTime(2026, 4, 26, 9, 0, 10),
              latitude: 35.159265,
              longitude: 129.060769,
              accuracy: 3,
              speed: const Value(0.03),
            ),
          );
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: DateTime(2026, 4, 26, 9, 0, 20),
              latitude: 35.159680,
              longitude: 129.060281,
              accuracy: 20,
              speed: const Value(0.04),
            ),
          );

      final route = await DayRouteRepository(database).loadForDate(date);

      expect(route.points, hasLength(1));
      expect(route.points.single.longitude, closeTo(129.06028, 0.0001));
    },
  );

  test('collapses slow gps drift around one place', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final date = DateTime(2026, 4, 26);

    for (final (index, latitude, longitude) in [
      (0, 35.15967, 129.06024),
      (1, 35.15950, 129.06040),
      (2, 35.15942, 129.06055),
    ]) {
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: DateTime(2026, 4, 26, 9, 0, index * 10),
              latitude: latitude,
              longitude: longitude,
              accuracy: 18,
              speed: const Value(1.0),
            ),
          );
    }

    final route = await DayRouteRepository(database).loadForDate(date);

    expect(route.rawPointCount, 3);
    expect(route.points, hasLength(1));
  });

  test('keeps moving route points even when they are close together', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final date = DateTime(2026, 4, 26);

    for (var i = 0; i < 3; i++) {
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: DateTime(2026, 4, 26, 9, 0, i * 10),
              latitude: 35.1596 + i * 0.00012,
              longitude: 129.0602,
              accuracy: 12,
              speed: const Value(2.0),
            ),
          );
    }

    final route = await DayRouteRepository(database).loadForDate(date);

    expect(route.rawPointCount, 3);
    expect(route.points, hasLength(3));
  });

  test('removes a single implausible gps spike from route display', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final date = DateTime(2026, 4, 26);

    for (final (seconds, latitude, longitude) in [
      (0, 35.15960, 129.06020),
      (10, 35.19960, 129.11020),
      (20, 35.15970, 129.06030),
      (30, 35.15982, 129.06045),
    ]) {
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: DateTime(
                2026,
                4,
                26,
                9,
              ).add(Duration(seconds: seconds)),
              latitude: latitude,
              longitude: longitude,
              accuracy: 8,
              speed: const Value(0.2),
            ),
          );
    }

    final route = await DayRouteRepository(database).loadForDate(date);

    expect(route.rawPointCount, 4);
    expect(route.points, hasLength(1));
    expect(route.points.any((point) => point.latitude > 35.19), isFalse);
  });

  test(
    'removes a short multi-point gps excursion that returns to the same area',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final date = DateTime(2026, 4, 26);
      final start = DateTime(2026, 4, 26, 9);

      for (final (seconds, latitude, longitude, speed) in [
        (0, 35.15960, 129.06020, 0.1),
        (10, 35.15964, 129.06024, 0.2),
        (20, 35.16220, 129.06300, 4.2),
        (30, 35.16235, 129.06310, 4.5),
        (40, 35.15966, 129.06026, 0.2),
        (50, 35.15968, 129.06028, 0.1),
      ]) {
        await database
            .into(database.locationPoints)
            .insert(
              LocationPointsCompanion.insert(
                timestamp: start.add(Duration(seconds: seconds)),
                latitude: latitude,
                longitude: longitude,
                accuracy: 12,
                speed: Value(speed),
              ),
            );
      }

      final route = await DayRouteRepository(database).loadForDate(date);

      expect(route.rawPointCount, 6);
      expect(route.points.any((point) => point.latitude > 35.162), isFalse);
      expect(route.points, hasLength(1));
    },
  );

  test('keeps a fast but consistent moving route', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final date = DateTime(2026, 4, 26);

    for (final (seconds, latitude, longitude) in [
      (0, 35.15960, 129.06020),
      (10, 35.16220, 129.06280),
      (20, 35.16480, 129.06540),
      (30, 35.16740, 129.06800),
    ]) {
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: DateTime(
                2026,
                4,
                26,
                9,
              ).add(Duration(seconds: seconds)),
              latitude: latitude,
              longitude: longitude,
              accuracy: 8,
              speed: const Value(20),
            ),
          );
    }

    final route = await DayRouteRepository(database).loadForDate(date);

    expect(route.rawPointCount, 4);
    expect(route.points, hasLength(4));
  });

  test(
    'collapses ambiguous walking-speed gps spikes around one place',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final date = DateTime(2026, 4, 26);

      for (final (index, latitude, longitude, speed) in [
        (0, 35.1596840, 129.0602311, 0.03),
        (1, 35.1599256, 129.0603356, 1.6),
        (2, 35.1596739, 129.0602520, 0.08),
        (3, 35.1594804, 129.0606160, 0.08),
      ]) {
        await database
            .into(database.locationPoints)
            .insert(
              LocationPointsCompanion.insert(
                timestamp: DateTime(2026, 4, 26, 12, 41, index * 10),
                latitude: latitude,
                longitude: longitude,
                accuracy: 18,
                speed: Value(speed),
              ),
            );
      }

      final route = await DayRouteRepository(database).loadForDate(date);

      expect(route.rawPointCount, 4);
      expect(route.points, hasLength(1));
    },
  );

  test('removes short low-speed gps excursions from route display', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final date = DateTime(2026, 4, 29);
    final start = DateTime(2026, 4, 29, 13, 29, 9);

    for (final (seconds, latitude, longitude, accuracy, speed) in [
      (0, 35.1596704, 129.0602497, 26.8, 0.73),
      (58, 35.1594776, 129.0604480, 23.9, 1.02),
      (68, 35.1600735, 129.0606744, 20.0, 2.52),
      (79, 35.1608132, 129.0611008, 15.6, 2.70),
      (100, 35.1608702, 129.0612149, 27.0, 0.30),
      (111, 35.1598465, 129.0607891, 24.0, 0.13),
      (140, 35.1596449, 129.0607010, 28.6, 0.11),
      (240, 35.1596508, 129.0602648, 13.3, 0.16),
    ]) {
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: start.add(Duration(seconds: seconds)),
              latitude: latitude,
              longitude: longitude,
              accuracy: accuracy,
              speed: Value(speed),
            ),
          );
    }

    final route = await DayRouteRepository(database).loadForDate(date);

    expect(route.rawPointCount, 8);
    expect(route.points.every((point) => point.latitude < 35.1600), isTrue);
    expect(route.points, hasLength(1));
  });

  test('uses resolved address when a place has no custom name', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final date = DateTime(2026, 4, 26);
    final placeId = await database
        .into(database.placeClusters)
        .insert(
          PlaceClustersCompanion.insert(
            centerLatitude: 37.5665,
            centerLongitude: 126.978,
            radiusMeters: 100,
            roadAddressName: const Value('서울 중구 세종대로 110'),
            addressName: const Value('서울 중구 태평로1가 31'),
            regionName: const Value('서울 중구 태평로1가'),
            addressResolvedAt: Value(date),
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
            startedAt: DateTime(2026, 4, 26, 10),
            endedAt: DateTime(2026, 4, 26, 11),
            durationMinutes: 60,
            representativeLatitude: 37.5665,
            representativeLongitude: 126.978,
          ),
        );

    final route = await DayRouteRepository(database).loadForDate(date);

    expect(route.visits.single.placeLabel, '서울 중구 세종대로 110');
  });
}
