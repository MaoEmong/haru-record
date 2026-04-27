import '../analysis/daily_summary_service.dart';
import 'insight_models.dart';
import 'insight_narrator.dart';
import 'pattern_analysis_models.dart';

class InsightGenerationService {
  InsightGenerationService({InsightNarrator? narrator})
    : _narrator = narrator ?? const RuleBasedInsightNarrator();

  final InsightNarrator _narrator;

  List<GeneratedInsight> generate({
    required DailySummarySnapshot yesterday,
    required DailySummaryBaseline recentAverage,
    List<PatternSignal> patternSignals = const [],
  }) {
    final insights = <GeneratedInsight>[];

    for (final signal in patternSignals) {
      insights.add(_patternInsight(signal));
    }

    final movementInsight = _movementInsight(yesterday, recentAverage);
    if (movementInsight != null) insights.add(movementInsight);

    final visitInsight = _visitInsight(yesterday, recentAverage);
    if (visitInsight != null) insights.add(visitInsight);

    if (yesterday.newPlaceCount > 0) {
      insights.add(
        _buildInsight(
          type: InsightType.newPlace,
          severity: InsightSeverity.notable,
          direction: InsightDirection.newValue,
          currentValue: yesterday.newPlaceCount,
          baselineValue: 0,
        ),
      );
    }

    insights.sort(_compareInsightStrength);
    return insights.take(2).toList(growable: false);
  }

  GeneratedInsight _patternInsight(PatternSignal signal) {
    final text = _narrator.narratePattern(signal);
    return GeneratedInsight(
      type: InsightType.routineTrend,
      severity: InsightSeverity.important,
      title: text.title,
      body: text.body,
      evidence: text.evidence,
    );
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
      return _buildInsight(
        type: InsightType.movementChange,
        severity: InsightSeverity.notable,
        direction: InsightDirection.lower,
        currentValue: yesterday.totalDistanceMeters,
        baselineValue: recentAverage.totalDistanceMeters,
      );
    }

    if (distanceHigher || movingHigher) {
      return _buildInsight(
        type: InsightType.movementChange,
        severity: InsightSeverity.notable,
        direction: InsightDirection.higher,
        currentValue: yesterday.totalDistanceMeters,
        baselineValue: recentAverage.totalDistanceMeters,
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
      return _buildInsight(
        type: InsightType.visitChange,
        severity: InsightSeverity.neutral,
        direction: InsightDirection.lower,
        currentValue: yesterday.visitCount,
        baselineValue: recentAverage.visitCount,
      );
    }

    if (yesterday.visitCount > recentAverage.visitCount) {
      return _buildInsight(
        type: InsightType.visitChange,
        severity: InsightSeverity.neutral,
        direction: InsightDirection.higher,
        currentValue: yesterday.visitCount,
        baselineValue: recentAverage.visitCount,
      );
    }

    return null;
  }

  GeneratedInsight _buildInsight({
    required InsightType type,
    required InsightSeverity severity,
    required InsightDirection direction,
    required num currentValue,
    required num baselineValue,
  }) {
    final text = _narrator.narrate(
      InsightNarrationContext(
        type: type,
        severity: severity,
        direction: direction,
        currentValue: currentValue,
        baselineValue: baselineValue,
      ),
    );
    return GeneratedInsight(
      type: type,
      severity: severity,
      title: text.title,
      body: text.body,
      evidence: text.evidence,
    );
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
      InsightType.routineTrend => 6,
      InsightType.movementChange => 5,
      InsightType.newPlace => 4,
      InsightType.longestStay => 3,
      InsightType.visitChange => 2,
      InsightType.lowConfidence => 1,
    };
  }
}
