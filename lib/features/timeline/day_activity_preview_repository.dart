import '../../core/geo/geo_math.dart';
import '../places/place_clustering_service.dart';
import '../settings/settings_models.dart';
import '../storage/app_database.dart';
import 'day_timeline_models.dart';
import 'day_timeline_repository.dart';
import 'location_point_deduplication.dart';
import 'route_display_point_cleaner.dart';

class DayActivityPreviewRepository {
  const DayActivityPreviewRepository(this._database);

  final AppDatabase _database;

  Future<DayActivityPreview> loadForDate(
    DateTime date, {
    AppSettings? settings,
  }) async {
    final summary = await _loadDailySummary(date);
    final timeline = await DayTimelineRepository(_database).loadForDate(date);
    final rawPoints = await _loadLocationPoints(date);
    final points = compactNearbyLocationPoints(rawPoints);
    final inferredTimeline = _inferTimelineFromRawPoints(
      rawPoints,
      settings ?? AppSettings.defaults(),
    );
    final visibleTimeline = _mergeTimelineItems(timeline, inferredTimeline);

    final fallbackTimeline = visibleTimeline.isNotEmpty || points.isEmpty
        ? visibleTimeline
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
        visitCount: summary.visitCount > 0
            ? summary.visitCount
            : inferredTimeline.length,
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

    final displayPoints = const RouteDisplayPointCleaner().clean(rawPoints);
    final totalDistance = _totalDistance(displayPoints);
    return DayActivityPreview(
      totalDistanceMeters: totalDistance,
      movingMinutes: totalDistance <= 0
          ? 0
          : rawPoints.last.timestamp
                .difference(rawPoints.first.timestamp)
                .inMinutes,
      visitCount: visibleTimeline.length,
      timeline: fallbackTimeline,
      pointCount: points.length,
      hasData: true,
    );
  }

  Future<DailySummary?> _loadDailySummary(DateTime date) async {
    final rows = await (_database.select(
      _database.dailySummaries,
    )..where((summary) => summary.date.equals(_dateKey(date)))).get();
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

  double _totalDistance(List<RouteDisplayPoint> points) {
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

  List<DayTimelineItem> _inferTimelineFromRawPoints(
    List<LocationPoint> rawPoints,
    AppSettings settings,
  ) {
    final visits =
        PlaceClusteringService(
          clusterRadiusMeters: settings.minimumMovementMeters.toDouble(),
          minimumStayMinutes: settings.minimumStayMinutes,
        ).detectVisits(
          rawPoints
              .map(
                (point) => TrackedPoint(
                  point.timestamp,
                  point.latitude,
                  point.longitude,
                  point.accuracy,
                  point.isMock,
                ),
              )
              .toList(growable: false),
        );

    return visits
        .map(
          (visit) => DayTimelineItem(
            timeLabel: _timeLabel(visit.startedAt),
            placeLabel: '머문 곳',
            durationLabel: '머문 곳으로 보여요',
            startedAt: visit.startedAt,
            endedAt: visit.endedAt,
            durationMinutes: visit.durationMinutes,
            latitude: visit.latitude,
            longitude: visit.longitude,
            isInferred: true,
          ),
        )
        .toList(growable: false);
  }

  List<DayTimelineItem> _mergeTimelineItems(
    List<DayTimelineItem> persisted,
    List<DayTimelineItem> inferred,
  ) {
    final merged = [
      ...persisted,
      for (final item in inferred)
        if (!_duplicatesPersistedVisit(item, persisted) &&
            !_duplicatesTimelineItem(item, persisted) &&
            !_duplicatesTimelineItem(
              item,
              inferred.takeWhile((other) => other != item).toList(),
            ))
          item,
    ]..sort(_compareTimelineItems);
    return merged;
  }

  bool _duplicatesPersistedVisit(
    DayTimelineItem inferred,
    List<DayTimelineItem> persisted,
  ) {
    final inferredStart = inferred.startedAt;
    final inferredEnd = inferred.endedAt;
    if (inferredStart == null || inferredEnd == null) return false;

    for (final item in persisted) {
      final start = item.startedAt;
      final end = item.endedAt;
      if (start == null || end == null) continue;
      if (inferredStart.isBefore(end) && inferredEnd.isAfter(start)) {
        return true;
      }
    }
    return _duplicatesTimelineItem(inferred, persisted);
  }

  bool _duplicatesTimelineItem(
    DayTimelineItem item,
    Iterable<DayTimelineItem> existingItems,
  ) {
    if (item.latitude == null || item.longitude == null) return false;
    for (final existing in existingItems) {
      if (existing.latitude == null || existing.longitude == null) continue;
      final distance = distanceMeters(
        item.latitude!,
        item.longitude!,
        existing.latitude!,
        existing.longitude!,
      );
      if (distance <= _samePlaceMergeRadiusMeters) return true;
    }
    return false;
  }

  int _compareTimelineItems(DayTimelineItem a, DayTimelineItem b) {
    final aTime = a.startedAt;
    final bTime = b.startedAt;
    if (aTime != null && bTime != null) return aTime.compareTo(bTime);
    return a.timeLabel.compareTo(b.timeLabel);
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

const _samePlaceMergeRadiusMeters = 80.0;

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
