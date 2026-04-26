import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/core/geo/geo_math.dart';

void main() {
  test('distanceMeters returns near-zero for identical coordinates', () {
    expect(distanceMeters(37.5665, 126.9780, 37.5665, 126.9780), lessThan(1));
  });

  test(
    'distanceMeters estimates Seoul city hall to Gangnam over 8000 meters',
    () {
      final distance = distanceMeters(37.5665, 126.9780, 37.4979, 127.0276);
      expect(distance, greaterThan(8000));
      expect(distance, lessThan(12000));
    },
  );

  test('distanceMeters stays finite for antipodal coordinates', () {
    final distance = distanceMeters(0, 0, 0, 180);

    expect(distance.isFinite, isTrue);
    expect(distance, greaterThan(20000000));
  });
}
