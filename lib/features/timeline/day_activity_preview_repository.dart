import 'dart:isolate';

import 'package:drift/drift.dart';

import '../../core/geo/geo_math.dart';
import '../../core/time/date_key.dart';
import '../places/place_label.dart';
import '../processing/location_post_processor.dart';
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
    final places = await _database.select(_database.placeClusters).get();
    final rawComputation = await _computeRawPreview(
      rawPoints,
      settings ?? AppSettings.defaults(),
    );
    final inferredTimeline = _labelKnownPlaces(
      rawComputation.inferredTimeline,
      places,
    );
    final visibleTimeline = _mergeTimelineItems(timeline, inferredTimeline);

    final fallbackTimeline =
        visibleTimeline.isNotEmpty || rawComputation.compactedPointCount == 0
        ? visibleTimeline
        : [
            DayTimelineItem(
              timeLabel: _timeLabel(rawPoints.last.timestamp),
              placeLabel: '최근 위치',
              durationLabel: '분석 중',
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
        pointCount: rawComputation.compactedPointCount,
        hasData: true,
      );
    }

    if (rawComputation.compactedPointCount == 0) {
      return DayActivityPreview(
        totalDistanceMeters: null,
        movingMinutes: null,
        visitCount: null,
        timeline: fallbackTimeline,
        pointCount: 0,
        hasData: false,
      );
    }

    return DayActivityPreview(
      totalDistanceMeters: rawComputation.totalDistanceMeters,
      movingMinutes: rawComputation.totalDistanceMeters <= 0
          ? 0
          : rawPoints.last.timestamp
                .difference(rawPoints.first.timestamp)
                .inMinutes,
      visitCount: visibleTimeline.length,
      timeline: fallbackTimeline,
      pointCount: rawComputation.compactedPointCount,
      hasData: true,
    );
  }

  Future<DailySummary?> _loadDailySummary(DateTime date) async {
    final rows = await (_database.select(
      _database.dailySummaries,
    )..where((summary) => summary.date.equals(dateKey(date)))).get();
    return rows.firstOrNull;
  }

  Future<List<LocationPoint>> _loadLocationPoints(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final points =
        await (_database.select(_database.locationPoints)..where(
              (point) =>
                  point.timestamp.isBiggerOrEqualValue(start) &
                  point.timestamp.isSmallerThanValue(end) &
                  point.isMock.equals(false) &
                  point.accuracy.isSmallerOrEqualValue(
                    maximumUsableAccuracyMeters,
                  ),
            ))
            .get();
    return points..sort((a, b) => a.timestamp.compareTo(b.timestamp));
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

  List<DayTimelineItem> _labelKnownPlaces(
    List<DayTimelineItem> inferred,
    List<PlaceCluster> places,
  ) {
    if (inferred.isEmpty || places.isEmpty) return inferred;

    return inferred
        .map((item) {
          final place = _findMatchingPlace(item, places);
          if (place == null) return item;
          return DayTimelineItem(
            timeLabel: item.timeLabel,
            placeLabel: placeLabel(place),
            durationLabel: '방문 기록',
            startedAt: item.startedAt,
            endedAt: item.endedAt,
            durationMinutes: item.durationMinutes,
            latitude: item.latitude,
            longitude: item.longitude,
            placeClusterId: place.id,
            isInferred: item.isInferred,
          );
        })
        .toList(growable: false);
  }

  PlaceCluster? _findMatchingPlace(
    DayTimelineItem item,
    List<PlaceCluster> places,
  ) {
    if (item.latitude == null || item.longitude == null) return null;
    return const LocationPostProcessor().findKnownPlace(
      latitude: item.latitude!,
      longitude: item.longitude!,
      knownPlaces: places,
    );
  }

  int _compareTimelineItems(DayTimelineItem a, DayTimelineItem b) {
    final aTime = a.startedAt;
    final bTime = b.startedAt;
    if (aTime != null && bTime != null) return aTime.compareTo(bTime);
    return a.timeLabel.compareTo(b.timeLabel);
  }

  String _timeLabel(DateTime time) => _previewTimeLabel(time);
}

Future<_RawPreviewComputation> _computeRawPreview(
  List<LocationPoint> rawPoints,
  AppSettings settings,
) async {
  if (rawPoints.length < _isolatePointThreshold) {
    return _computeRawPreviewSync(rawPoints, settings);
  }
  try {
    return await Isolate.run(() => _computeRawPreviewSync(rawPoints, settings));
  } on Object {
    return _computeRawPreviewSync(rawPoints, settings);
  }
}

_RawPreviewComputation _computeRawPreviewSync(
  List<LocationPoint> rawPoints,
  AppSettings settings,
) {
  final compactedPointCount = compactNearbyLocationPoints(rawPoints).length;
  final displayPoints = const LocationPostProcessor().cleanRouteDisplayPoints(
    rawPoints,
  );
  final totalDistance = _totalDistance(displayPoints);
  final inferredTimeline = _inferTimelineFromRawPoints(rawPoints, settings);
  return _RawPreviewComputation(
    compactedPointCount: compactedPointCount,
    totalDistanceMeters: totalDistance,
    inferredTimeline: inferredTimeline,
  );
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
  return const LocationPostProcessor().inferTimeline(
    points: rawPoints,
    settings: settings,
  );
}

String _previewTimeLabel(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class _RawPreviewComputation {
  const _RawPreviewComputation({
    required this.compactedPointCount,
    required this.totalDistanceMeters,
    required this.inferredTimeline,
  });

  final int compactedPointCount;
  final double totalDistanceMeters;
  final List<DayTimelineItem> inferredTimeline;
}

const _samePlaceMergeRadiusMeters = 80.0;
const _isolatePointThreshold = 80;

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
