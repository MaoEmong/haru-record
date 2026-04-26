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
}
