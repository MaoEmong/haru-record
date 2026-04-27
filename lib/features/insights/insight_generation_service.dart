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
          title: '새롭게 자주 머문 곳이 생겼어요',
          body: '최근 흐름에 없던 머문 곳이 기록에 남았어요.',
          evidence: '새롭게 보인 곳 ${yesterday.newPlaceCount}곳',
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
        title: '어제는 조금 조용한 하루였어요',
        body: '최근 며칠보다 이동이 적고 차분했어요.',
        evidence:
            '${yesterday.totalDistanceMeters.round()}m, 최근 평균 ${recentAverage.totalDistanceMeters.round()}m',
      );
    }

    if (distanceHigher || movingHigher) {
      return GeneratedInsight(
        type: InsightType.movementChange,
        severity: InsightSeverity.notable,
        title: '어제는 평소보다 많이 움직였어요',
        body: '최근 며칠보다 이동이 많은 하루였어요.',
        evidence:
            '${yesterday.totalDistanceMeters.round()}m, 최근 평균 ${recentAverage.totalDistanceMeters.round()}m',
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
        title: '어제는 머문 곳이 적었어요',
        body: '최근 며칠보다 들른 곳이 적은 하루였어요.',
        evidence:
            '${yesterday.visitCount}회 방문, 최근 평균 ${recentAverage.visitCount}회',
      );
    }

    if (yesterday.visitCount > recentAverage.visitCount) {
      return GeneratedInsight(
        type: InsightType.visitChange,
        severity: InsightSeverity.neutral,
        title: '어제는 여러 곳을 들렀어요',
        body: '최근 며칠보다 머문 곳이 많은 하루였어요.',
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
