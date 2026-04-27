import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/analysis/daily_summary_service.dart';
import 'package:projectapp_1/features/insights/pattern_analysis_service.dart';

void main() {
  test('detects decreasing movement trend across recent days', () {
    final service = PatternAnalysisService();
    final days = [
      _summary('2026-04-20', 5000, 60, 3),
      _summary('2026-04-21', 4200, 52, 3),
      _summary('2026-04-22', 3400, 43, 2),
      _summary('2026-04-23', 2600, 35, 2),
      _summary('2026-04-24', 1800, 24, 1),
    ];

    final signals = service.analyze(days);

    expect(
      signals.map((signal) => signal.type),
      contains(PatternSignalType.decreasingMovement),
    );
  });

  test(
    'does not emit trend signal when there are fewer than four summaries',
    () {
      final service = PatternAnalysisService();
      final signals = service.analyze([
        _summary('2026-04-22', 3000, 30, 2),
        _summary('2026-04-23', 2500, 25, 2),
        _summary('2026-04-24', 2000, 20, 2),
      ]);

      expect(signals, isEmpty);
    },
  );
}

DailySummarySnapshot _summary(
  String date,
  double distance,
  int movingMinutes,
  int visitCount,
) {
  return DailySummarySnapshot(
    date: DateTime.parse(date),
    totalDistanceMeters: distance,
    movingMinutes: movingMinutes,
    stationaryMinutes: 120,
    visitCount: visitCount,
    newPlaceCount: 0,
  );
}
