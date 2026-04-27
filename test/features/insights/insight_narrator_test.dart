import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/insights/insight_models.dart';
import 'package:projectapp_1/features/insights/insight_narrator.dart';
import 'package:projectapp_1/features/insights/pattern_analysis_models.dart';

void main() {
  test('rule based narrator produces non-empty movement copy', () {
    const narrator = RuleBasedInsightNarrator();

    final text = narrator.narrate(
      const InsightNarrationContext(
        type: InsightType.movementChange,
        severity: InsightSeverity.notable,
        direction: InsightDirection.lower,
        currentValue: 1000,
        baselineValue: 3000,
      ),
    );

    expect(text.title, isNotEmpty);
    expect(text.body, isNotEmpty);
    expect(text.evidence, isNotEmpty);
  });

  test('rule based narrator produces Korean trend copy', () {
    const narrator = RuleBasedInsightNarrator();

    final text = narrator.narratePattern(
      const PatternSignal(
        type: PatternSignalType.decreasingMovement,
        strength: 0.7,
        evidence: '5000m에서 1800m로 줄었어요',
      ),
    );

    expect(text.title, contains('최근'));
    expect(text.body, contains('흐름'));
    expect(text.evidence, '5000m에서 1800m로 줄었어요');
  });
}
