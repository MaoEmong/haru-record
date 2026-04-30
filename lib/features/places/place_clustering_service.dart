import 'dart:math' as math;

import '../../core/geo/geo_math.dart';

class TrackedPoint {
  const TrackedPoint(
    this.timestamp,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.isMock, {
    this.speed,
  });

  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double accuracy;
  final bool isMock;
  final double? speed;
}

class DetectedVisit {
  const DetectedVisit({
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
    required this.latitude,
    required this.longitude,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final int durationMinutes;
  final double latitude;
  final double longitude;
}

class PlaceClusteringService {
  const PlaceClusteringService({
    required this.clusterRadiusMeters,
    required this.minimumStayMinutes,
    this.maximumAccuracyMeters = 200,
  });

  final double clusterRadiusMeters;
  final int minimumStayMinutes;
  final double maximumAccuracyMeters;

  List<DetectedVisit> detectVisits(List<TrackedPoint> points) {
    final eligiblePoints = points.where(_isEligiblePoint).toList();
    if (eligiblePoints.length < 2) return const [];

    final sorted = [...eligiblePoints]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final smoothed = _removeGpsNoise(sorted);
    if (smoothed.length < 2) return const [];

    final visits = <DetectedVisit>[];
    var windowStart = smoothed.first;
    final window = <TrackedPoint>[windowStart];

    for (final point in smoothed.skip(1)) {
      final distance = distanceMeters(
        windowStart.latitude,
        windowStart.longitude,
        point.latitude,
        point.longitude,
      );

      if (distance <= _effectiveClusterRadiusMeters) {
        window.add(point);
        continue;
      }

      _addVisitIfLongEnough(window, visits);
      window
        ..clear()
        ..add(point);
      windowStart = point;
    }

    _addVisitIfLongEnough(window, visits);
    return visits;
  }

  List<TrackedPoint> _removeGpsNoise(List<TrackedPoint> sorted) {
    return _removeShortLowSpeedExcursions(_removeIsolatedJumps(sorted));
  }

  List<TrackedPoint> _removeIsolatedJumps(List<TrackedPoint> sorted) {
    if (sorted.length < 3) return sorted;

    final smoothed = <TrackedPoint>[sorted.first];
    for (var index = 1; index < sorted.length - 1; index += 1) {
      final previous = smoothed.last;
      final current = sorted[index];
      final next = sorted[index + 1];
      if (_isIsolatedJump(previous, current, next)) continue;
      smoothed.add(current);
    }
    smoothed.add(sorted.last);
    return smoothed;
  }

  List<TrackedPoint> _removeShortLowSpeedExcursions(List<TrackedPoint> sorted) {
    if (sorted.length < 4) return sorted;

    final kept = <TrackedPoint>[];
    var index = 0;
    while (index < sorted.length) {
      final anchor = kept.isEmpty ? sorted[index] : kept.last;
      final point = sorted[index];
      if (_distance(anchor, point) <= _stableRadiusMeters) {
        kept.add(point);
        index++;
        continue;
      }

      final returnIndex = _findShortExcursionReturn(sorted, index, anchor);
      if (returnIndex == null) {
        kept.add(point);
        index++;
        continue;
      }

      index = returnIndex;
    }

    return kept;
  }

  int? _findShortExcursionReturn(
    List<TrackedPoint> sorted,
    int excursionStartIndex,
    TrackedPoint anchor,
  ) {
    final excursionStart = sorted[excursionStartIndex];
    if (!_isLowSpeed(excursionStart)) return null;

    for (
      var index = excursionStartIndex + 1;
      index < sorted.length &&
          index <= excursionStartIndex + _maxExcursionPoints;
      index++
    ) {
      final point = sorted[index];
      final elapsed = point.timestamp
          .difference(excursionStart.timestamp)
          .abs();
      if (elapsed > _maxExcursionDuration) return null;
      if (!_isLowSpeed(point)) return null;
      if (_distance(anchor, point) <= _stableRadiusMeters) {
        return index;
      }
    }
    return null;
  }

  bool _isIsolatedJump(
    TrackedPoint previous,
    TrackedPoint current,
    TrackedPoint next,
  ) {
    final previousToNext = distanceMeters(
      previous.latitude,
      previous.longitude,
      next.latitude,
      next.longitude,
    );
    if (previousToNext > _effectiveClusterRadiusMeters) return false;

    final previousToCurrent = distanceMeters(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    );
    final currentToNext = distanceMeters(
      current.latitude,
      current.longitude,
      next.latitude,
      next.longitude,
    );
    return previousToCurrent > _effectiveClusterRadiusMeters &&
        currentToNext > _effectiveClusterRadiusMeters;
  }

  double _distance(TrackedPoint a, TrackedPoint b) {
    return distanceMeters(a.latitude, a.longitude, b.latitude, b.longitude);
  }

  bool _isLowSpeed(TrackedPoint point) {
    final speed = point.speed;
    return speed == null || speed <= _lowSpeedExcursionMetersPerSecond;
  }

  void _addVisitIfLongEnough(
    List<TrackedPoint> window,
    List<DetectedVisit> visits,
  ) {
    if (window.length < 2) return;

    final start = window.first.timestamp;
    final end = window.last.timestamp;
    final duration = end.difference(start).inMinutes;
    if (duration < minimumStayMinutes) return;

    visits.add(
      DetectedVisit(
        startedAt: start,
        endedAt: end,
        durationMinutes: duration,
        latitude:
            window.map((point) => point.latitude).reduce((a, b) => a + b) /
            window.length,
        longitude: _averageLongitude(window),
      ),
    );
  }

  bool _isEligiblePoint(TrackedPoint point) {
    return !point.isMock && point.accuracy <= maximumAccuracyMeters;
  }

  double get _effectiveClusterRadiusMeters {
    return math.max(clusterRadiusMeters, _minimumStableClusterRadiusMeters);
  }

  double _averageLongitude(List<TrackedPoint> window) {
    var x = 0.0;
    var y = 0.0;

    for (final point in window) {
      final radians = point.longitude * math.pi / 180;
      x += math.cos(radians);
      y += math.sin(radians);
    }

    return math.atan2(y / window.length, x / window.length) * 180 / math.pi;
  }

  static const _stableRadiusMeters = 100.0;
  static const _minimumStableClusterRadiusMeters = 80.0;
  static const _maxExcursionDuration = Duration(minutes: 3);
  static const _maxExcursionPoints = 18;
  static const _lowSpeedExcursionMetersPerSecond = 3.0;
}
