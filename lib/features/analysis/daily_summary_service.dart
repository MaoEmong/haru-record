class VisitSnapshot {
  const VisitSnapshot({
    required this.durationMinutes,
    required this.distanceFromPreviousMeters,
    required this.isNewPlace,
    this.movingMinutesFromPrevious,
    this.placeClusterId,
  });

  final int durationMinutes;
  final double distanceFromPreviousMeters;
  final bool isNewPlace;
  final int? movingMinutesFromPrevious;
  final int? placeClusterId;
}

class DailySummarySnapshot {
  const DailySummarySnapshot({
    required this.date,
    required this.totalDistanceMeters,
    required this.movingMinutes,
    required this.stationaryMinutes,
    required this.visitCount,
    required this.newPlaceCount,
    this.longestStayPlaceId,
  });

  final DateTime date;
  final double totalDistanceMeters;
  final int movingMinutes;
  final int stationaryMinutes;
  final int visitCount;
  final int newPlaceCount;
  final int? longestStayPlaceId;
}

class DailySummaryBaseline {
  const DailySummaryBaseline({
    required this.totalDistanceMeters,
    required this.movingMinutes,
    required this.visitCount,
  });

  final double totalDistanceMeters;
  final int movingMinutes;
  final int visitCount;
}

class DailySummaryService {
  DailySummarySnapshot buildSummary({
    required DateTime date,
    required List<VisitSnapshot> visits,
  }) {
    final stationaryMinutes = visits.fold<int>(
      0,
      (total, visit) => total + visit.durationMinutes,
    );
    final totalDistanceMeters = visits.fold<double>(
      0,
      (total, visit) => total + visit.distanceFromPreviousMeters,
    );
    final movingMinutes = visits.fold<int>(
      0,
      (total, visit) =>
          total +
          (visit.movingMinutesFromPrevious ??
              _estimateMovingMinutes(visit.distanceFromPreviousMeters)),
    );
    final visitCount = _placeCount(visits);
    final newPlaceCount = _newPlaceCount(visits);

    return DailySummarySnapshot(
      date: date,
      totalDistanceMeters: totalDistanceMeters,
      movingMinutes: movingMinutes,
      stationaryMinutes: stationaryMinutes,
      visitCount: visitCount,
      newPlaceCount: newPlaceCount,
      longestStayPlaceId: _longestStayPlaceId(visits),
    );
  }

  int _placeCount(List<VisitSnapshot> visits) {
    final placeIds = visits
        .map((visit) => visit.placeClusterId)
        .whereType<int>()
        .toSet();
    return placeIds.isEmpty ? visits.length : placeIds.length;
  }

  int _newPlaceCount(List<VisitSnapshot> visits) {
    final newPlaceIds = visits
        .where((visit) => visit.isNewPlace)
        .map((visit) => visit.placeClusterId)
        .whereType<int>()
        .toSet();
    if (newPlaceIds.isNotEmpty) return newPlaceIds.length;
    return visits.where((visit) => visit.isNewPlace).length;
  }

  int _estimateMovingMinutes(double distanceMeters) {
    if (distanceMeters <= 0) return 0;
    return (distanceMeters / _assumedTravelMetersPerMinute).round().clamp(
      1,
      1440,
    );
  }

  int? _longestStayPlaceId(List<VisitSnapshot> visits) {
    VisitSnapshot? longestVisit;
    for (final visit in visits) {
      if (visit.placeClusterId == null) continue;
      if (longestVisit == null ||
          visit.durationMinutes > longestVisit.durationMinutes) {
        longestVisit = visit;
      }
    }

    return longestVisit?.placeClusterId;
  }
}

const double _assumedTravelMetersPerMinute = 80;
