import '../../core/geo/geo_math.dart';
import '../storage/app_database.dart';

class KnownPlaceMatcher {
  const KnownPlaceMatcher({
    this.minimumMatchRadiusMeters = knownPlaceMatchRadiusMeters,
  });

  final double minimumMatchRadiusMeters;

  PlaceCluster? findKnownPlace({
    required double latitude,
    required double longitude,
    required List<PlaceCluster> knownPlaces,
  }) {
    PlaceCluster? closest;
    var closestDistance = double.infinity;
    for (final place in knownPlaces) {
      final distance = distanceMeters(
        latitude,
        longitude,
        place.centerLatitude,
        place.centerLongitude,
      );
      final radius = place.radiusMeters > minimumMatchRadiusMeters
          ? place.radiusMeters
          : minimumMatchRadiusMeters;
      if (distance <= radius && distance < closestDistance) {
        closest = place;
        closestDistance = distance;
      }
    }
    return closest;
  }
}

const knownPlaceMatchRadiusMeters = 80.0;
