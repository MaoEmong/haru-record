import '../../core/geo/coordinate_validation.dart';
import '../../core/geo/geo_math.dart';
import '../storage/app_database.dart';

class RouteDisplayPoint {
  const RouteDisplayPoint({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
  });

  factory RouteDisplayPoint.fromLocationPoint(LocationPoint point) {
    return RouteDisplayPoint(
      timestamp: point.timestamp,
      latitude: point.latitude,
      longitude: point.longitude,
      accuracy: point.accuracy,
      speed: point.speed,
    );
  }

  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? speed;
}

class RouteDisplayPointCleaner {
  const RouteDisplayPointCleaner();

  List<RouteDisplayPoint> clean(List<LocationPoint> rawPoints) {
    final groups = _groups(rawPoints);
    return groups.map((group) => group.representative).toList(growable: false);
  }

  List<_RoutePointGroup> _groups(List<LocationPoint> rawPoints) {
    final accuratePoints =
        rawPoints
            .where((point) => point.accuracy <= _maximumRouteAccuracyMeters)
            .where(
              (point) =>
                  isValidCoordinate(point.latitude, point.longitude) &&
                  isValidAccuracy(point.accuracy) &&
                  (point.speed == null || point.speed!.isFinite),
            )
            .toList(growable: false)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (accuratePoints.length <= 2) {
      return [for (final point in accuratePoints) _RoutePointGroup(point)];
    }

    final groups = <_RoutePointGroup>[];
    for (final point in accuratePoints) {
      final currentGroup = groups.isEmpty ? null : groups.last;
      if (currentGroup != null && currentGroup.canAbsorb(point)) {
        currentGroup.add(point);
      } else {
        groups.add(_RoutePointGroup(point));
      }
    }

    return groups;
  }

  static const _maximumRouteAccuracyMeters = 80.0;
}

class _RoutePointGroup {
  _RoutePointGroup(LocationPoint first) : _points = [first];

  final List<LocationPoint> _points;

  bool canAbsorb(LocationPoint point) {
    final distance = distanceMeters(
      representative.latitude,
      representative.longitude,
      point.latitude,
      point.longitude,
    );
    if (_isMovingSpeed(representative.speed) || _isMoving(point)) {
      return distance <= _movingClusterRadiusMeters;
    }
    if (_isSlowSpeed(representative.speed) && _isSlow(point)) {
      return distance <= _stationaryDriftRadiusMeters;
    }
    return distance <= _jitterClusterRadiusMeters;
  }

  void add(LocationPoint point) {
    _points.add(point);
  }

  RouteDisplayPoint get representative {
    if (_points.length > 1 && _points.every(_isSlow)) {
      final centerLatitude = _median(_points.map((point) => point.latitude));
      final centerLongitude = _median(_points.map((point) => point.longitude));
      final best = _points.reduce((a, b) => a.accuracy < b.accuracy ? a : b);
      return RouteDisplayPoint(
        timestamp: _points.first.timestamp,
        latitude: centerLatitude,
        longitude: centerLongitude,
        accuracy: best.accuracy,
        speed: best.speed,
      );
    }
    return RouteDisplayPoint.fromLocationPoint(
      _points.reduce(
        (best, point) => point.accuracy < best.accuracy ? point : best,
      ),
    );
  }

  bool _isMoving(LocationPoint point) {
    return _isMovingSpeed(point.speed);
  }

  bool _isSlow(LocationPoint point) {
    return _isSlowSpeed(point.speed);
  }

  bool _isMovingSpeed(double? speed) {
    return speed != null && speed >= _movingSpeedMetersPerSecond;
  }

  bool _isSlowSpeed(double? speed) {
    return speed == null || speed < _movingSpeedMetersPerSecond;
  }

  double _median(Iterable<double> values) {
    final sorted = values.toList()..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[middle];
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }

  static const _movingClusterRadiusMeters = 5.0;
  static const _jitterClusterRadiusMeters = 25.0;
  static const _stationaryDriftRadiusMeters = 180.0;
  static const _movingSpeedMetersPerSecond = 1.8;
}
