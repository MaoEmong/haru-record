import 'package:drift/drift.dart';

import '../storage/app_database.dart';
import '../places/place_label.dart';
import 'day_timeline_models.dart';

class DayTimelineRepository {
  const DayTimelineRepository(this._database);

  final AppDatabase _database;

  Future<List<DayTimelineItem>> loadForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final visits =
        await (_database.select(_database.visits)..where(
              (visit) =>
                  visit.startedAt.isBiggerOrEqualValue(start) &
                  visit.startedAt.isSmallerThanValue(end),
            ))
            .get();
    visits.sort((a, b) => a.startedAt.compareTo(b.startedAt));

    final places = await _database.select(_database.placeClusters).get();
    return visits
        .map((visit) {
          final place = _findPlace(places, visit.placeClusterId);
          return DayTimelineItem(
            timeLabel: _timeLabel(visit.startedAt),
            placeLabel: placeLabel(place),
            durationLabel: _durationLabel(),
            startedAt: visit.startedAt,
            endedAt: visit.endedAt,
            durationMinutes: visit.durationMinutes,
            latitude: visit.representativeLatitude,
            longitude: visit.representativeLongitude,
          );
        })
        .toList(growable: false);
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
