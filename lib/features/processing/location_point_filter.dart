import '../../core/geo/coordinate_validation.dart';
import '../storage/app_database.dart';

class LocationPointFilter {
  const LocationPointFilter({
    this.maximumAccuracyMeters = maximumUsableAccuracyMeters,
  });

  final double maximumAccuracyMeters;

  List<LocationPoint> clean(List<LocationPoint> points) {
    return points
        .where(
          (point) =>
              !point.isMock &&
              isValidCoordinate(point.latitude, point.longitude) &&
              isValidAccuracy(point.accuracy) &&
              point.accuracy <= maximumAccuracyMeters,
        )
        .toList(growable: false)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
}

const maximumUsableAccuracyMeters = 200.0;
