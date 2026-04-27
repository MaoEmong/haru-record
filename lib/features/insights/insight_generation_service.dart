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
          title: '새로운 장소가 감지됐어요',
          body: '자주 방문할 가능성이 있는 새 장소가 감지됐어요.',
          evidence: '새 장소 후보 ${yesterday.newPlaceCount}개',
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
        title: '평소보다 이동이 적었어요',
        body: '어제는 최근 평균보다 이동과 거리가 적은 날이었어요.',
        evidence:
            '${yesterday.totalDistanceMeters.round()}m 대 최근 평균 ${recentAverage.totalDistanceMeters.round()}m',
      );
    }

    if (distanceHigher || movingHigher) {
      return GeneratedInsight(
        type: InsightType.movementChange,
        severity: InsightSeverity.notable,
        title: '평소보다 이동이 많았어요',
        body: '어제는 최근 평균보다 더 활발하게 움직인 날이었어요.',
        evidence:
            '${yesterday.totalDistanceMeters.round()}m 대 최근 평균 ${recentAverage.totalDistanceMeters.round()}m',
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
        title: '방문한 장소가 평소보다 적었어요',
        body: '방문 횟수가 최근 평균보다 낮았어요.',
        evidence:
            '${yesterday.visitCount}회 방문, 최근 평균 ${recentAverage.visitCount}회',
      );
    }

    if (yesterday.visitCount > recentAverage.visitCount) {
      return GeneratedInsight(
        type: InsightType.visitChange,
        severity: InsightSeverity.neutral,
        title: '방문한 장소가 평소보다 많았어요',
        body: '방문 횟수가 최근 평균보다 높았어요.',
        evidence:
            '${yesterday.visitCount}회 방문, 최근 평균 ${recentAverage.visitCount}회',
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
