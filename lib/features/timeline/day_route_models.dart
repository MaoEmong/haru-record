class DayRouteSnapshot {
  const DayRouteSnapshot({
    required this.points,
    required this.rawPointCount,
    required this.visits,
  });

  final List<DayRoutePoint> points;
  final int rawPointCount;
  final List<DayRouteVisit> visits;
}

class DayRoutePoint {
  const DayRoutePoint({
    required this.timeLabel,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });

  final String timeLabel;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
}

class DayRouteVisit {
  const DayRouteVisit({
    required this.timeLabel,
    required this.placeLabel,
    required this.latitude,
    required this.longitude,
    required this.durationLabel,
  });

  final String timeLabel;
  final String placeLabel;
  final double latitude;
  final double longitude;
  final String durationLabel;
}
