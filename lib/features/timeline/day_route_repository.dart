import '../storage/app_database.dart';
import '../places/place_label.dart';
import 'day_route_models.dart';

class DayRouteRepository {
  const DayRouteRepository(this._database);

  final AppDatabase _database;

  Future<DayRouteSnapshot> loadForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final allPoints = await _database.select(_database.locationPoints).get();
    final points =
        allPoints
            .where(
              (point) =>
                  !point.timestamp.isBefore(start) &&
                  point.timestamp.isBefore(end) &&
                  !point.isMock &&
                  point.accuracy <= 200,
            )
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final allVisits = await _database.select(_database.visits).get();
    final visits =
        allVisits
            .where(
              (visit) =>
                  !visit.startedAt.isBefore(start) &&
                  visit.startedAt.isBefore(end),
            )
            .toList()
          ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final places = await _database.select(_database.placeClusters).get();

    return DayRouteSnapshot(
      points: points
          .map(
            (point) => DayRoutePoint(
              timeLabel: _timeLabel(point.timestamp),
              latitude: point.latitude,
              longitude: point.longitude,
              accuracyMeters: point.accuracy,
            ),
          )
          .toList(growable: false),
      visits: visits
          .map((visit) {
            final place = _findPlace(places, visit.placeClusterId);
            return DayRouteVisit(
              timeLabel: _timeLabel(visit.startedAt),
              placeLabel: placeLabel(place),
              latitude: visit.representativeLatitude,
              longitude: visit.representativeLongitude,
              durationLabel: _durationLabel(visit.durationMinutes),
            );
          })
          .toList(growable: false),
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

  String _durationLabel(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final rest = minutes % 60;
      if (rest == 0) return '$hours시간 머문 곳';
      return '$hours시간 $rest분 머문 곳';
    }
    return '$minutes분 머문 곳';
  }
}
