import '../analysis/daily_summary_service.dart';
import 'insight_models.dart';

class InsightGenerationService {
  List<GeneratedInsight> generate({
    required DailySummarySnapshot yesterday,
    required DailySummaryBaseline recentAverage,
  }) {
    final insights = <GeneratedInsight>[];

    final movementInsight = _movementInsight(yesterday, recentAverage);
    if (movementInsight != null) insights.add(movementInsight);

    final visitInsight = _visitInsight(yesterday, recentAverage);
    if (visitInsight != null) insights.add(visitInsight);

    if (yesterday.newPlaceCount > 0) {
      insights.add(
        GeneratedInsight(
          type: InsightType.newPlace,
          severity: InsightSeverity.notable,
          title: 'A new place appeared',
          body: 'A new frequently visited place candidate was detected.',
          evidence: '${yesterday.newPlaceCount} new place candidates',
        ),
      );
    }

    insights.sort(_compareInsightStrength);
    return insights.take(2).toList(growable: false);
  }

  GeneratedInsight? _movementInsight(
    DailySummarySnapshot yesterday,
    DailySummaryBaseline recentAverage,
  ) {
    final distanceLower =
        recentAverage.totalDistanceMeters > 0 &&
        yesterday.totalDistanceMeters < recentAverage.totalDistanceMeters * 0.5;
    final movingLower =
        recentAverage.movingMinutes > 0 &&
        yesterday.movingMinutes < recentAverage.movingMinutes * 0.5;
    final distanceHigher =
        recentAverage.totalDistanceMeters > 0 &&
        yesterday.totalDistanceMeters > recentAverage.totalDistanceMeters * 1.5;
    final movingHigher =
        recentAverage.movingMinutes > 0 &&
        yesterday.movingMinutes > recentAverage.movingMinutes * 1.5;

    if (distanceLower || movingLower) {
      return GeneratedInsight(
        type: InsightType.movementChange,
        severity: InsightSeverity.notable,
        title: 'Movement was lower than usual',
        body:
            'Yesterday was quieter than your recent average for movement and distance.',
        evidence:
            '${yesterday.totalDistanceMeters.round()}m vs ${recentAverage.totalDistanceMeters.round()}m recent average',
      );
    }

    if (distanceHigher || movingHigher) {
      return GeneratedInsight(
        type: InsightType.movementChange,
        severity: InsightSeverity.notable,
        title: 'Movement was higher than usual',
        body:
            'Yesterday was more active than your recent average for movement and distance.',
        evidence:
            '${yesterday.totalDistanceMeters.round()}m vs ${recentAverage.totalDistanceMeters.round()}m recent average',
      );
    }

    return null;
  }

  GeneratedInsight? _visitInsight(
    DailySummarySnapshot yesterday,
    DailySummaryBaseline recentAverage,
  ) {
    if (recentAverage.visitCount <= 0) return null;

    if (yesterday.visitCount < recentAverage.visitCount) {
      return GeneratedInsight(
        type: InsightType.visitChange,
        severity: InsightSeverity.neutral,
        title: 'You visited fewer places',
        body: 'Your visit count was below your recent average.',
        evidence:
            '${yesterday.visitCount} visits vs ${recentAverage.visitCount} recent average',
      );
    }

    if (yesterday.visitCount > recentAverage.visitCount) {
      return GeneratedInsight(
        type: InsightType.visitChange,
        severity: InsightSeverity.neutral,
        title: 'You visited more places',
        body: 'Your visit count was above your recent average.',
        evidence:
            '${yesterday.visitCount} visits vs ${recentAverage.visitCount} recent average',
      );
    }

    return null;
  }

  int _compareInsightStrength(GeneratedInsight a, GeneratedInsight b) {
    final severityComparison =
        _severityRank(b.severity) - _severityRank(a.severity);
    if (severityComparison != 0) return severityComparison;
    return _typeRank(b.type) - _typeRank(a.type);
  }

  int _severityRank(InsightSeverity severity) {
    return switch (severity) {
      InsightSeverity.important => 3,
      InsightSeverity.notable => 2,
      InsightSeverity.neutral => 1,
    };
  }

  int _typeRank(InsightType type) {
    return switch (type) {
      InsightType.movementChange => 5,
      InsightType.newPlace => 4,
      InsightType.longestStay => 3,
      InsightType.visitChange => 2,
      InsightType.lowConfidence => 1,
    };
  }
}
