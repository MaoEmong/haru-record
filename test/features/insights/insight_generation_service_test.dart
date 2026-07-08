import 'package:flutter_test/flutter_test.dart';
import 'package:haru_record/features/analysis/daily_summary_service.dart';
import 'package:haru_record/features/insights/insight_generation_service.dart';
import 'package:haru_record/features/insights/insight_models.dart';
import 'package:haru_record/features/insights/insight_narrator.dart';
import 'package:haru_record/features/insights/pattern_analysis_models.dart';

void main() {
  test('generates lower movement insight against baseline', () {
    final service = InsightGenerationService();
    final date = DateTime(2026, 4, 25);

    final insights = service.generate(
      yesterday: DailySummarySnapshot(
        date: date,
        totalDistanceMeters: 500,
        movingMinutes: 10,
        stationaryMinutes: 700,
        visitCount: 1,
        newPlaceCount: 0,
      ),
      recentAverage: DailySummaryBaseline(
        totalDistanceMeters: 2000,
        movingMinutes: 45,
        visitCount: 3,
      ),
    );

    expect(insights.first.title, '어제는 조금 조용한 하루였어요');
    expect(insights.first.body, contains('최근 며칠'));
  });

  test('generates higher movement insight against baseline', () {
    final service = InsightGenerationService();

    final insights = service.generate(
      yesterday: DailySummarySnapshot(
        date: DateTime(2026, 4, 25),
        totalDistanceMeters: 5000,
        movingMinutes: 90,
        stationaryMinutes: 500,
        visitCount: 3,
        newPlaceCount: 0,
      ),
      recentAverage: DailySummaryBaseline(
        totalDistanceMeters: 2000,
        movingMinutes: 45,
        visitCount: 3,
      ),
    );

    expect(insights.first.title, '어제는 평소보다 많이 움직였어요');
  });

  test(
    'generates distance insight when moving minute baseline is unavailable',
    () {
      final service = InsightGenerationService();

      final insights = service.generate(
        yesterday: DailySummarySnapshot(
          date: DateTime(2026, 4, 25),
          totalDistanceMeters: 500,
          movingMinutes: 0,
          stationaryMinutes: 700,
          visitCount: 1,
          newPlaceCount: 0,
        ),
        recentAverage: DailySummaryBaseline(
          totalDistanceMeters: 2000,
          movingMinutes: 0,
          visitCount: 1,
        ),
      );

      expect(insights.first.type, InsightType.movementChange);
    },
  );

  test('keeps the two strongest insight candidates', () {
    final service = InsightGenerationService();

    final insights = service.generate(
      yesterday: DailySummarySnapshot(
        date: DateTime(2026, 4, 25),
        totalDistanceMeters: 500,
        movingMinutes: 10,
        stationaryMinutes: 700,
        visitCount: 1,
        newPlaceCount: 1,
      ),
      recentAverage: DailySummaryBaseline(
        totalDistanceMeters: 2000,
        movingMinutes: 45,
        visitCount: 3,
      ),
    );

    expect(insights, hasLength(2));
    expect(
      insights.map((insight) => insight.type),
      containsAll([InsightType.movementChange, InsightType.newPlace]),
    );
    expect(
      insights.map((insight) => insight.type),
      isNot(contains(InsightType.visitChange)),
    );
  });

  test('generates decreasing movement trend insight from pattern signal', () {
    final service = InsightGenerationService();

    final insights = service.generate(
      yesterday: DailySummarySnapshot(
        date: DateTime(2026, 4, 25),
        totalDistanceMeters: 1000,
        movingMinutes: 15,
        stationaryMinutes: 700,
        visitCount: 1,
        newPlaceCount: 0,
      ),
      recentAverage: DailySummaryBaseline(
        totalDistanceMeters: 3000,
        movingMinutes: 30,
        visitCount: 2,
      ),
      patternSignals: const [
        PatternSignal(
          type: PatternSignalType.decreasingMovement,
          strength: 0.7,
          evidence: '최근 이동이 계속 줄었어요',
        ),
      ],
    );

    expect(insights.first.type, InsightType.routineTrend);
    expect(insights.first.title, contains('최근'));
    expect(insights.first.evidence, '최근 이동이 계속 줄었어요');
  });

  test('uses injected narrator wording for generated insights', () {
    final service = InsightGenerationService(narrator: _FakeInsightNarrator());

    final insights = service.generate(
      yesterday: DailySummarySnapshot(
        date: DateTime(2026, 4, 25),
        totalDistanceMeters: 500,
        movingMinutes: 10,
        stationaryMinutes: 700,
        visitCount: 1,
        newPlaceCount: 1,
      ),
      recentAverage: DailySummaryBaseline(
        totalDistanceMeters: 2000,
        movingMinutes: 45,
        visitCount: 3,
      ),
    );

    expect(insights.first.title, 'custom movementChange');
    expect(insights.first.body, 'custom notable body');
    expect(insights.first.evidence, 'custom evidence');
  });
}

class _FakeInsightNarrator implements InsightNarrator {
  @override
  InsightText narrate(InsightNarrationContext context) {
    return InsightText(
      title: 'custom ${context.type.name}',
      body: 'custom ${context.severity.name} body',
      evidence: 'custom evidence',
    );
  }

  @override
  InsightText narratePattern(PatternSignal signal) {
    return InsightText(
      title: 'custom pattern',
      body: 'custom pattern body',
      evidence: signal.evidence,
    );
  }
}
