import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/places/place_clustering_service.dart';

void main() {
  test('creates a visit when points stay near the same place long enough', () {
    final service = PlaceClusteringService(
      clusterRadiusMeters: 120,
      minimumStayMinutes: 10,
    );
    final start = DateTime(2026, 4, 25, 10);

    final result = service.detectVisits([
      TrackedPoint(start, 37.5665, 126.9780, 20, false),
      TrackedPoint(
        start.add(const Duration(minutes: 5)),
        37.5666,
        126.9781,
        20,
        false,
      ),
      TrackedPoint(
        start.add(const Duration(minutes: 11)),
        37.5667,
        126.9781,
        20,
        false,
      ),
    ]);

    expect(result, hasLength(1));
    expect(result.single.durationMinutes, 11);
  });

  test('ignores short stays', () {
    final service = PlaceClusteringService(
      clusterRadiusMeters: 120,
      minimumStayMinutes: 10,
    );
    final start = DateTime(2026, 4, 25, 10);

    final result = service.detectVisits([
      TrackedPoint(start, 37.5665, 126.9780, 20, false),
      TrackedPoint(
        start.add(const Duration(minutes: 3)),
        37.5666,
        126.9781,
        20,
        false,
      ),
    ]);

    expect(result, isEmpty);
  });

  test('ignores mock and low accuracy points', () {
    final service = PlaceClusteringService(
      clusterRadiusMeters: 120,
      minimumStayMinutes: 10,
    );
    final start = DateTime(2026, 4, 25, 10);

    final result = service.detectVisits([
      TrackedPoint(start, 37.5665, 126.9780, 20, false),
      TrackedPoint(
        start.add(const Duration(minutes: 6)),
        37.5666,
        126.9781,
        20,
        true,
      ),
      TrackedPoint(
        start.add(const Duration(minutes: 11)),
        37.5667,
        126.9781,
        500,
        false,
      ),
    ]);

    expect(result, isEmpty);
  });

  test('keeps representative longitude near the antimeridian', () {
    final service = PlaceClusteringService(
      clusterRadiusMeters: 500,
      minimumStayMinutes: 10,
    );
    final start = DateTime(2026, 4, 25, 10);

    final result = service.detectVisits([
      TrackedPoint(start, 0, 179.999, 20, false),
      TrackedPoint(
        start.add(const Duration(minutes: 11)),
        0,
        -179.999,
        20,
        false,
      ),
    ]);

    expect(result, hasLength(1));
    expect(result.single.longitude.abs(), greaterThan(179.9));
  });

  test('ignores isolated jumps inside a stationary stay', () {
    final service = PlaceClusteringService(
      clusterRadiusMeters: 50,
      minimumStayMinutes: 10,
    );
    final start = DateTime(2026, 4, 25, 10);

    final result = service.detectVisits([
      TrackedPoint(start, 37.5665, 126.9780, 20, false),
      TrackedPoint(
        start.add(const Duration(minutes: 5)),
        37.56655,
        126.97805,
        20,
        false,
      ),
      TrackedPoint(
        start.add(const Duration(minutes: 6)),
        37.5700,
        126.9820,
        80,
        false,
      ),
      TrackedPoint(
        start.add(const Duration(minutes: 11)),
        37.5666,
        126.9781,
        20,
        false,
      ),
    ]);

    expect(result, hasLength(1));
    expect(result.single.durationMinutes, 11);
  });

  test('ignores short low-speed GPS excursions inside a stationary stay', () {
    final service = PlaceClusteringService(
      clusterRadiusMeters: 50,
      minimumStayMinutes: 10,
    );
    final start = DateTime(2026, 4, 29, 13, 20);

    final result = service.detectVisits([
      TrackedPoint(start, 35.1596704, 129.0602497, 26.8, false, speed: 0.73),
      TrackedPoint(
        start.add(const Duration(minutes: 9)),
        35.1594776,
        129.0604480,
        23.9,
        false,
        speed: 1.02,
      ),
      TrackedPoint(
        start.add(const Duration(minutes: 9, seconds: 10)),
        35.1600735,
        129.0606744,
        20.0,
        false,
        speed: 2.52,
      ),
      TrackedPoint(
        start.add(const Duration(minutes: 9, seconds: 21)),
        35.1608132,
        129.0611008,
        15.6,
        false,
        speed: 2.70,
      ),
      TrackedPoint(
        start.add(const Duration(minutes: 10, seconds: 54)),
        35.1596449,
        129.0607010,
        28.6,
        false,
        speed: 0.11,
      ),
      TrackedPoint(
        start.add(const Duration(minutes: 16)),
        35.1596508,
        129.0602648,
        13.3,
        false,
        speed: 0.16,
      ),
    ]);

    expect(result, hasLength(1));
    expect(result.single.durationMinutes, 16);
    expect(result.single.latitude, closeTo(35.15965, 0.0002));
  });
}
