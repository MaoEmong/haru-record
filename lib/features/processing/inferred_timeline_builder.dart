import '../places/place_label.dart';
import '../settings/settings_models.dart';
import '../storage/app_database.dart';
import '../timeline/day_timeline_models.dart';
import 'known_place_matcher.dart';
import 'visit_detection_processor.dart';

class InferredTimelineBuilder {
  const InferredTimelineBuilder({
    this.visitDetectionProcessor = const VisitDetectionProcessor(),
    this.knownPlaceMatcher = const KnownPlaceMatcher(),
  });

  final VisitDetectionProcessor visitDetectionProcessor;
  final KnownPlaceMatcher knownPlaceMatcher;

  List<DayTimelineItem> build({
    required List<LocationPoint> points,
    required AppSettings settings,
    List<PlaceCluster> knownPlaces = const [],
  }) {
    return visitDetectionProcessor
        .detectVisits(points: points, settings: settings)
        .map((visit) {
          final place = knownPlaceMatcher.findKnownPlace(
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

  String _timeLabel(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
