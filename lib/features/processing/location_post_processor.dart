import '../../core/geo/coordinate_validation.dart';
import '../../core/geo/geo_math.dart';
import '../places/place_clustering_service.dart';
import '../places/place_label.dart';
import '../settings/settings_models.dart';
import '../storage/app_database.dart';
import '../timeline/day_timeline_models.dart';
import '../timeline/route_display_point_cleaner.dart';

class LocationPostProcessor {
  const LocationPostProcessor();

  List<LocationPoint> cleanTrackablePoints(List<LocationPoint> points) {
    return points
        .where(
          (point) =>
              !point.isMock &&
              isValidCoordinate(point.latitude, point.longitude) &&
              isValidAccuracy(point.accuracy) &&
              point.accuracy <= maximumUsableAccuracyMeters,
        )
        .toList(growable: false)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  List<RouteDisplayPoint> cleanRouteDisplayPoints(List<LocationPoint> points) {
    return const RouteDisplayPointCleaner().clean(cleanTrackablePoints(points));
  }

  List<DetectedVisit> detectVisits({
    required List<LocationPoint> points,
    required AppSettings settings,
    PlaceClusteringService? clusteringService,
  }) {
    final cleanPoints = cleanTrackablePoints(points);
    final service =
        clusteringService ??
        PlaceClusteringService(
          clusterRadiusMeters: settings.minimumMovementMeters.toDouble(),
          minimumStayMinutes: settings.minimumStayMinutes,
        );
    return service.detectVisits(
      cleanPoints
          .map(
            (point) => TrackedPoint(
              point.timestamp,
              point.latitude,
              point.longitude,
              point.accuracy,
              point.isMock,
              speed: point.speed,
            ),
          )
          .toList(growable: false),
    );
  }

  List<DayTimelineItem> inferTimeline({
    required List<LocationPoint> points,
    required AppSettings settings,
    List<PlaceCluster> knownPlaces = const [],
  }) {
    return detectVisits(points: points, settings: settings)
        .map((visit) {
          final place = findKnownPlace(
            latitude: visit.latitude,
            longitude: visit.longitude,
            knownPlaces: knownPlaces,
          );
          return DayTimelineItem(
            timeLabel: _timeLabel(visit.startedAt),
            placeLabel: place == null ? '새 장소 후보' : placeLabel(place),
            durationLabel: place == null ? '저장 가능' : '머문 기록',
            startedAt: visit.startedAt,
            endedAt: visit.endedAt,
            durationMinutes: visit.durationMinutes,
            latitude: visit.latitude,
            longitude: visit.longitude,
            placeClusterId: place?.id,
            isInferred: true,
          );
        })
        .toList(growable: false);
  }

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
      final radius = place.radiusMeters > knownPlaceMatchRadiusMeters
          ? place.radiusMeters
          : knownPlaceMatchRadiusMeters;
      if (distance <= radius && distance < closestDistance) {
        closest = place;
        closestDistance = distance;
      }
    }
    return closest;
  }

  String _timeLabel(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

const maximumUsableAccuracyMeters = 200.0;
const knownPlaceMatchRadiusMeters = 80.0;
