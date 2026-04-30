import '../places/place_clustering_service.dart';
import '../settings/settings_models.dart';
import '../storage/app_database.dart';
import 'location_point_filter.dart';

class VisitDetectionProcessor {
  const VisitDetectionProcessor({this.filter = const LocationPointFilter()});

  final LocationPointFilter filter;

  List<DetectedVisit> detectVisits({
    required List<LocationPoint> points,
    required AppSettings settings,
    PlaceClusteringService? clusteringService,
  }) {
    final service =
        clusteringService ??
        PlaceClusteringService(
          clusterRadiusMeters: settings.minimumMovementMeters.toDouble(),
          minimumStayMinutes: settings.minimumStayMinutes,
        );
    return service.detectVisits(
      filter.clean(points).map(_trackedPoint).toList(growable: false),
    );
  }

  TrackedPoint _trackedPoint(LocationPoint point) {
    return TrackedPoint(
      point.timestamp,
      point.latitude,
      point.longitude,
      point.accuracy,
      point.isMock,
      speed: point.speed,
    );
  }
}
