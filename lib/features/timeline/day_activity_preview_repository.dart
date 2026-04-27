import '../../core/geo/geo_math.dart';
import '../storage/app_database.dart';
import 'day_timeline_models.dart';
import 'day_timeline_repository.dart';
import 'location_point_deduplication.dart';

class DayActivityPreviewRepository {
  const DayActivityPreviewRepository(this._database);

  final AppDatabase _database;

  Future<DayActivityPreview> loadForDate(DateTime date) async {
    final summary = await _loadDailySummary(date);
    final timeline = await DayTimelineRepository(_database).loadForDate(date);
    final rawPoints = await _loadLocationPoints(date);
    final points = compactNearbyLocationPoints(rawPoints);

    final fallbackTimeline = timeline.isNotEmpty || points.isEmpty
        ? timeline
        : [
            DayTimelineItem(
              timeLabel: _timeLabel(points.last.timestamp),
              placeLabel: '최근 위치 기록',
              durationLabel: '위치 기록 ${points.length}개 · 머문 곳은 판단 중',
            ),
          ];

    if (summary != null) {
      return DayActivityPreview(
        totalDistanceMeters: summary.totalDistanceMeters,
        movingMinutes: summary.movingMinutes,
        visitCount: summary.visitCount,
        timeline: fallbackTimeline,
        pointCount: points.length,
        hasData: true,
      );
    }

    if (points.isEmpty) {
      return DayActivityPreview(
        totalDistanceMeters: null,
        movingMinutes: null,
        visitCount: null,
        timeline: fallbackTimeline,
        pointCount: 0,
        hasData: false,
      );
    }

    final totalDistance = _totalDistance(points);
    return DayActivityPreview(
      totalDistanceMeters: totalDistance,
      movingMinutes: totalDistance <= 0
          ? 0
          : rawPoints.last.timestamp
                .difference(rawPoints.first.timestamp)
                .inMinutes,
      visitCount: timeline.length,
      timeline: fallbackTimeline,
      pointCount: points.length,
      hasData: true,
    );
  }

  Future<DailySummary?> _loadDailySummary(DateTime date) async {
    final rows =
        await (_database.select(_database.dailySummaries)
              ..where((summary) => summary.date.equals(_dateKey(date))))
            .get();
    return rows.firstOrNull;
  }

  Future<List<LocationPoint>> _loadLocationPoints(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final points = await _database.select(_database.locationPoints).get();
    return points
        .where(
          (point) =>
              !point.timestamp.isBefore(start) &&
              point.timestamp.isBefore(end) &&
              !point.isMock &&
              point.accuracy <= 200,
        )
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  double _totalDistance(List<LocationPoint> points) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      total += distanceMeters(
        previous.latitude,
        previous.longitude,
        current.latitude,
        current.longitude,
      );
    }
    return total;
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _timeLabel(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class DayActivityPreview {
  const DayActivityPreview({
    required this.totalDistanceMeters,
    required this.movingMinutes,
    required this.visitCount,
    required this.timeline,
    required this.pointCount,
    required this.hasData,
  });

  final double? totalDistanceMeters;
  final int? movingMinutes;
  final int? visitCount;
  final List<DayTimelineItem> timeline;
  final int pointCount;
  final bool hasData;
}
