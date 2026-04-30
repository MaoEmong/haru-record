import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/processing/location_post_processor.dart';
import 'package:projectapp_1/features/settings/settings_models.dart';
import 'package:projectapp_1/features/storage/app_database.dart';

void main() {
  group('LocationPostProcessor', () {
    const processor = LocationPostProcessor();

    test('filters unusable points and sorts by timestamp', () {
      final start = DateTime(2026, 4, 30, 9);

      final result = processor.cleanTrackablePoints([
        _point(start.add(const Duration(minutes: 2)), 37.2, 127.2),
        _point(start.add(const Duration(minutes: 1)), 37.1, 127.1),
        _point(start, 91, 127),
        _point(start, 37, 127, accuracy: 250),
        _point(start, 37, 127, isMock: true),
      ]);

      expect(result.map((point) => point.timestamp), [
        start.add(const Duration(minutes: 1)),
        start.add(const Duration(minutes: 2)),
      ]);
    });

    test('detects visits after cleaning raw location points', () {
      final start = DateTime(2026, 4, 30, 9);

      final visits = processor.detectVisits(
        points: [
          _point(start, 37.5665, 126.9780),
          _point(start.add(const Duration(minutes: 6)), 37.56651, 126.97801),
          _point(start.add(const Duration(minutes: 11)), 37.56652, 126.97802),
          _point(
            start.add(const Duration(minutes: 12)),
            37.6,
            127,
            isMock: true,
          ),
        ],
        settings: AppSettings.defaults().copyWith(
          minimumMovementMeters: 50,
          minimumStayMinutes: 10,
        ),
      );

      expect(visits, hasLength(1));
      expect(visits.single.durationMinutes, 11);
    });

    test('matches the closest known place within the effective radius', () {
      final now = DateTime(2026, 4, 30);
      final near = _place(
        id: 1,
        latitude: 37.5665,
        longitude: 126.9780,
        radiusMeters: 30,
        now: now,
      );
      final closer = _place(
        id: 2,
        latitude: 37.56655,
        longitude: 126.97805,
        radiusMeters: 30,
        now: now,
      );

      final result = processor.findKnownPlace(
        latitude: 37.56656,
        longitude: 126.97806,
        knownPlaces: [near, closer],
      );

      expect(result?.id, 2);
    });

    test('infers timeline items and labels known places', () {
      final start = DateTime(2026, 4, 30, 9);
      final now = DateTime(2026, 4, 30);

      final result = processor.inferTimeline(
        points: [
          _point(start, 37.5665, 126.9780),
          _point(start.add(const Duration(minutes: 12)), 37.56651, 126.97801),
        ],
        settings: AppSettings.defaults().copyWith(
          minimumMovementMeters: 50,
          minimumStayMinutes: 10,
        ),
        knownPlaces: [
          _place(
            id: 7,
            latitude: 37.5665,
            longitude: 126.9780,
            radiusMeters: 50,
            displayName: '학원',
            now: now,
          ),
        ],
      );

      expect(result, hasLength(1));
      expect(result.single.timeLabel, '09:00');
      expect(result.single.placeLabel, '학원');
      expect(result.single.durationLabel, '머문 기록');
      expect(result.single.placeClusterId, 7);
      expect(result.single.isInferred, isTrue);
    });
  });
}

LocationPoint _point(
  DateTime timestamp,
  double latitude,
  double longitude, {
  double accuracy = 20,
  bool isMock = false,
  double? speed,
}) {
  return LocationPoint(
    id: 0,
    timestamp: timestamp,
    latitude: latitude,
    longitude: longitude,
    accuracy: accuracy,
    speed: speed,
    isMock: isMock,
    source: 'test',
  );
}

PlaceCluster _place({
  required int id,
  required double latitude,
  required double longitude,
  required double radiusMeters,
  required DateTime now,
  String? displayName,
}) {
  return PlaceCluster(
    id: id,
    centerLatitude: latitude,
    centerLongitude: longitude,
    radiusMeters: radiusMeters,
    displayName: displayName,
    addressName: null,
    roadAddressName: null,
    regionName: null,
    addressResolvedAt: null,
    createdAt: now,
    updatedAt: now,
    visitCount: 1,
  );
}
