import '../../core/geo/geo_math.dart';
import '../storage/app_database.dart';

const nearbyLocationPointDistanceMeters = 30.0;

List<LocationPoint> compactNearbyLocationPoints(
  List<LocationPoint> points, {
  double thresholdMeters = nearbyLocationPointDistanceMeters,
}) {
  if (points.length < 2) return points;

  final compacted = <LocationPoint>[];
  for (final point in points) {
    if (compacted.isEmpty) {
      compacted.add(point);
      continue;
    }

    final previous = compacted.last;
    final distance = distanceMeters(
      previous.latitude,
      previous.longitude,
      point.latitude,
      point.longitude,
    );
    if (distance > thresholdMeters) {
      compacted.add(point);
    }
  }
  return compacted;
}
