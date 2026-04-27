import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/analysis/daily_summary_service.dart';
import 'package:projectapp_1/features/insights/insight_generation_service.dart';
import 'package:projectapp_1/features/insights/insight_models.dart';

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

    expect(insights.first.title, '평소보다 이동이 적었어요');
    expect(insights.first.body, contains('최근 평균'));
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

    expect(insights.first.title, '평소보다 이동이 많았어요');
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
}
