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
    final routePoints = _withoutGpsNoise(accuratePoints);
    if (routePoints.length <= 2) {
      return [for (final point in routePoints) _RoutePointGroup(point)];
    }

    final groups = <_RoutePointGroup>[];
    for (final point in routePoints) {
      final currentGroup = groups.isEmpty ? null : groups.last;
      if (currentGroup != null && currentGroup.canAbsorb(point)) {
        currentGroup.add(point);
      } else {
        groups.add(_RoutePointGroup(point));
      }
    }

    return groups;
  }

  List<LocationPoint> _withoutGpsNoise(List<LocationPoint> points) {
    return _withoutShortLowSpeedExcursions(_withoutImplausibleSpikes(points));
  }

  List<LocationPoint> _withoutImplausibleSpikes(List<LocationPoint> points) {
    if (points.length < 3) return points;

    final filtered = <LocationPoint>[points.first];
    for (var index = 1; index < points.length - 1; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final next = points[index + 1];
      if (!_isImplausibleSpike(previous, current, next)) {
        filtered.add(current);
      }
    }
    filtered.add(points.last);
    return filtered;
  }

  List<LocationPoint> _withoutShortLowSpeedExcursions(
    List<LocationPoint> points,
  ) {
    if (points.length < 4) return points;

    final kept = <LocationPoint>[];
    var index = 0;
    while (index < points.length) {
      final anchor = kept.isEmpty ? points[index] : kept.last;
      final point = points[index];
      if (_distance(anchor, point) <= _stableRadiusMeters) {
        kept.add(point);
        index++;
        continue;
      }

      final returnIndex = _findShortExcursionReturn(points, index, anchor);
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
    List<LocationPoint> points,
    int excursionStartIndex,
    LocationPoint anchor,
  ) {
    final excursionStart = points[excursionStartIndex];

    var farthestDetourDistance = _distance(anchor, excursionStart);
    for (
      var index = excursionStartIndex + 1;
      index < points.length &&
          index <= excursionStartIndex + _maxExcursionPoints;
      index++
    ) {
      final point = points[index];
      final elapsed = point.timestamp
          .difference(excursionStart.timestamp)
          .abs();
      if (elapsed > _maxExcursionDuration) return null;
      farthestDetourDistance = _max(
        farthestDetourDistance,
        _distance(anchor, point),
      );
      if (_distance(anchor, point) <= _stableRadiusMeters) {
        final allLowSpeed = points
            .sublist(excursionStartIndex, index)
            .every((point) => _isLowSpeed(point.speed));
        if (allLowSpeed ||
            _isShortOutAndBackExcursion(
              anchor: anchor,
              excursionStart: excursionStart,
              returnPoint: point,
              farthestDetourDistance: farthestDetourDistance,
            )) {
          return index;
        }
        return null;
      }
    }
    return null;
  }

  bool _isShortOutAndBackExcursion({
    required LocationPoint anchor,
    required LocationPoint excursionStart,
    required LocationPoint returnPoint,
    required double farthestDetourDistance,
  }) {
    final excursionSeconds =
        returnPoint.timestamp
            .difference(excursionStart.timestamp)
            .inMilliseconds
            .abs() /
        1000;
    if (excursionSeconds <= 0) return false;
    final impliedSpeed = farthestDetourDistance / excursionSeconds;
    final anchorToReturn = _distance(anchor, returnPoint);
    return farthestDetourDistance >= _minimumExcursionDistanceMeters &&
        anchorToReturn <= _stableRadiusMeters &&
        impliedSpeed >= _minimumOutAndBackSpeedMetersPerSecond;
  }

  bool _isImplausibleSpike(
    LocationPoint previous,
    LocationPoint current,
    LocationPoint next,
  ) {
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
    final previousToNext = distanceMeters(
      previous.latitude,
      previous.longitude,
      next.latitude,
      next.longitude,
    );

    final inboundSeconds =
        current.timestamp.difference(previous.timestamp).inMilliseconds.abs() /
        1000;
    final outboundSeconds =
        next.timestamp.difference(current.timestamp).inMilliseconds.abs() /
        1000;
    if (inboundSeconds <= 0 || outboundSeconds <= 0) return false;

    final inboundSpeed = previousToCurrent / inboundSeconds;
    final outboundSpeed = currentToNext / outboundSeconds;
    final isFastOutAndBack =
        inboundSpeed >= _maximumPlausibleSpikeSpeedMetersPerSecond &&
        outboundSpeed >= _maximumPlausibleSpikeSpeedMetersPerSecond;
    if (!isFastOutAndBack) return false;

    final detourDistance = previousToCurrent + currentToNext;
    final isSinglePointDetour =
        previousToNext <= _maximumReturnDistanceMeters ||
        detourDistance >= previousToNext * _minimumSpikeDetourRatio;
    final isMeaningfulJump =
        previousToCurrent >= _minimumSpikeDistanceMeters &&
        currentToNext >= _minimumSpikeDistanceMeters;
    return isSinglePointDetour && isMeaningfulJump;
  }

  double _distance(LocationPoint a, LocationPoint b) {
    return distanceMeters(a.latitude, a.longitude, b.latitude, b.longitude);
  }

  double _max(double a, double b) {
    return a > b ? a : b;
  }

  bool _isLowSpeed(double? speed) {
    return speed == null || speed <= _lowSpeedExcursionMetersPerSecond;
  }

  static const _maximumRouteAccuracyMeters = 80.0;
  static const _maximumPlausibleSpikeSpeedMetersPerSecond = 45.0;
  static const _minimumSpikeDistanceMeters = 120.0;
  static const _maximumReturnDistanceMeters = 220.0;
  static const _minimumSpikeDetourRatio = 4.0;
  static const _stableRadiusMeters = 50.0;
  static const _minimumExcursionDistanceMeters = 120.0;
  static const _minimumOutAndBackSpeedMetersPerSecond = 4.0;
  static const _maxExcursionDuration = Duration(minutes: 3);
  static const _maxExcursionPoints = 18;
  static const _lowSpeedExcursionMetersPerSecond = 3.0;
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
