import 'dart:math' as math;

import '../../core/geo/geo_math.dart';

class TrackedPoint {
  const TrackedPoint(
    this.timestamp,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.isMock,
  );

  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double accuracy;
  final bool isMock;
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
    final visits = <DetectedVisit>[];
    var windowStart = sorted.first;
    final window = <TrackedPoint>[windowStart];

    for (final point in sorted.skip(1)) {
      final distance = distanceMeters(
        windowStart.latitude,
        windowStart.longitude,
        point.latitude,
        point.longitude,
      );

      if (distance <= clusterRadiusMeters) {
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
}
