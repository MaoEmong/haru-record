import 'dart:math' as math;

const double earthRadiusMeters = 6371000;

double distanceMeters(
  double startLatitude,
  double startLongitude,
  double endLatitude,
  double endLongitude,
) {
  final startLat = _toRadians(startLatitude);
  final endLat = _toRadians(endLatitude);
  final deltaLat = _toRadians(endLatitude - startLatitude);
  final deltaLng = _toRadians(endLongitude - startLongitude);

  final a =
      math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
      math.cos(startLat) *
          math.cos(endLat) *
          math.sin(deltaLng / 2) *
          math.sin(deltaLng / 2);
  final clampedA = a.clamp(0, 1).toDouble();
  final c = 2 * math.atan2(math.sqrt(clampedA), math.sqrt(1 - clampedA));
  return earthRadiusMeters * c;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
