export 'known_place_matcher.dart' show knownPlaceMatchRadiusMeters;
export 'location_point_filter.dart' show maximumUsableAccuracyMeters;

import '../places/place_clustering_service.dart';
import '../settings/settings_models.dart';
import '../storage/app_database.dart';
import '../timeline/day_timeline_models.dart';
import '../timeline/route_display_point_cleaner.dart';
import 'inferred_timeline_builder.dart';
import 'known_place_matcher.dart';
import 'location_point_filter.dart';
import 'visit_detection_processor.dart';

class LocationPostProcessor {
  const LocationPostProcessor({
    this.pointFilter = const LocationPointFilter(),
    this.visitDetectionProcessor = const VisitDetectionProcessor(),
    this.inferredTimelineBuilder = const InferredTimelineBuilder(),
    this.knownPlaceMatcher = const KnownPlaceMatcher(),
    this.routeDisplayPointCleaner = const RouteDisplayPointCleaner(),
  });

  final LocationPointFilter pointFilter;
  final VisitDetectionProcessor visitDetectionProcessor;
  final InferredTimelineBuilder inferredTimelineBuilder;
  final KnownPlaceMatcher knownPlaceMatcher;
  final RouteDisplayPointCleaner routeDisplayPointCleaner;

  List<LocationPoint> cleanTrackablePoints(List<LocationPoint> points) {
    return pointFilter.clean(points);
  }

  List<RouteDisplayPoint> cleanRouteDisplayPoints(List<LocationPoint> points) {
    return routeDisplayPointCleaner.clean(cleanTrackablePoints(points));
  }

  List<DetectedVisit> detectVisits({
    required List<LocationPoint> points,
    required AppSettings settings,
    PlaceClusteringService? clusteringService,
  }) {
    return visitDetectionProcessor.detectVisits(
      points: points,
      settings: settings,
      clusteringService: clusteringService,
    );
  }

  List<DayTimelineItem> inferTimeline({
    required List<LocationPoint> points,
    required AppSettings settings,
    List<PlaceCluster> knownPlaces = const [],
  }) {
    return inferredTimelineBuilder.build(
      points: points,
      settings: settings,
      knownPlaces: knownPlaces,
    );
  }

  PlaceCluster? findKnownPlace({
    required double latitude,
    required double longitude,
    required List<PlaceCluster> knownPlaces,
  }) {
    return knownPlaceMatcher.findKnownPlace(
      latitude: latitude,
      longitude: longitude,
      knownPlaces: knownPlaces,
    );
  }
}
