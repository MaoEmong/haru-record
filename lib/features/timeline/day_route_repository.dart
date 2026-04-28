import '../../core/geo/coordinate_validation.dart';
import '../storage/app_database.dart';
import '../places/place_label.dart';
import 'day_route_models.dart';
import 'route_display_point_cleaner.dart';

class DayRouteRepository {
  const DayRouteRepository(this._database);

  final AppDatabase _database;

  Future<DayRouteSnapshot> loadForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final allPoints = await _database.select(_database.locationPoints).get();
    final rawPoints =
        allPoints
            .where(
              (point) =>
                  !point.timestamp.isBefore(start) &&
                  point.timestamp.isBefore(end) &&
                  !point.isMock &&
                  point.accuracy <= 200 &&
                  isValidCoordinate(point.latitude, point.longitude) &&
                  isValidAccuracy(point.accuracy),
            )
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final allVisits = await _database.select(_database.visits).get();
    final visits =
        allVisits
            .where(
              (visit) =>
                  !visit.startedAt.isBefore(start) &&
                  visit.startedAt.isBefore(end) &&
                  isValidCoordinate(
                    visit.representativeLatitude,
                    visit.representativeLongitude,
                  ),
            )
            .toList()
          ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final places = await _database.select(_database.placeClusters).get();

    final displayPoints = const RouteDisplayPointCleaner().clean(rawPoints);

    return DayRouteSnapshot(
      rawPointCount: rawPoints.length,
      points: displayPoints
          .map((point) => _routePoint(point))
          .toList(growable: false),
      visits: visits
          .map((visit) {
            final place = _findPlace(places, visit.placeClusterId);
            return DayRouteVisit(
              timeLabel: _timeLabel(visit.startedAt),
              placeLabel: placeLabel(place),
              latitude: visit.representativeLatitude,
              longitude: visit.representativeLongitude,
              durationLabel: _durationLabel(),
            );
          })
          .toList(growable: false),
    );
  }

  DayRoutePoint _routePoint(RouteDisplayPoint point) {
    return DayRoutePoint(
      timeLabel: _timeLabel(point.timestamp),
      latitude: point.latitude,
      longitude: point.longitude,
      accuracyMeters: point.accuracy,
    );
  }

  PlaceCluster? _findPlace(List<PlaceCluster> places, int? placeClusterId) {
    if (placeClusterId == null) return null;
    for (final place in places) {
      if (place.id == placeClusterId) return place;
    }
    return null;
  }

  String _timeLabel(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _durationLabel() => '머문 기록';
}
