import 'insight_models.dart';
import 'pattern_analysis_models.dart';

class InsightText {
  const InsightText({
    required this.title,
    required this.body,
    required this.evidence,
  });

  final String title;
  final String body;
  final String evidence;
}

class InsightNarrationContext {
  const InsightNarrationContext({
    required this.type,
    required this.severity,
    required this.direction,
    required this.currentValue,
    required this.baselineValue,
  });

  final InsightType type;
  final InsightSeverity severity;
  final InsightDirection direction;
  final num currentValue;
  final num baselineValue;
}

enum InsightDirection { lower, higher, newValue }

abstract interface class InsightNarrator {
  InsightText narrate(InsightNarrationContext context);

  InsightText narratePattern(PatternSignal signal);
}

class RuleBasedInsightNarrator implements InsightNarrator {
  const RuleBasedInsightNarrator();

  @override
  InsightText narrate(InsightNarrationContext context) {
    return switch (context.type) {
      InsightType.routineTrend => const InsightText(
        title: '최근 흐름이 달라지고 있어요',
        body: '며칠간의 기록을 함께 보면 평소와 다른 흐름이 보여요.',
        evidence: '최근 기록 비교',
      ),
      InsightType.movementChange => _movementText(context),
      InsightType.visitChange => _visitText(context),
      InsightType.newPlace => _newPlaceText(context),
      InsightType.longestStay || InsightType.lowConfidence => const InsightText(
        title: '하루 흐름이 조금 달랐어요',
        body: '최근 며칠과 다른 움직임이 있었어요.',
        evidence: '최근 평균과 비교',
      ),
    };
  }

  @override
  InsightText narratePattern(PatternSignal signal) {
    return switch (signal.type) {
      PatternSignalType.decreasingMovement => InsightText(
        title: '최근 이동이 차분해지고 있어요',
        body: '며칠간의 흐름을 보면 이동량이 줄어드는 쪽으로 이어지고 있어요.',
        evidence: signal.evidence,
      ),
      PatternSignalType.increasingMovement => InsightText(
        title: '최근 이동 반경이 넓어지고 있어요',
        body: '며칠간의 흐름을 보면 더 많이 움직이는 날이 이어지고 있어요.',
        evidence: signal.evidence,
      ),
      PatternSignalType.decreasingVisits => InsightText(
        title: '최근 머무는 곳이 단순해지고 있어요',
        body: '방문한 곳의 수가 줄어드는 흐름이 보여요.',
        evidence: signal.evidence,
      ),
      PatternSignalType.increasingVisits => InsightText(
        title: '최근 들르는 곳이 다양해지고 있어요',
        body: '방문한 곳의 수가 늘어나는 흐름이 보여요.',
        evidence: signal.evidence,
      ),
    };
  }

  InsightText _movementText(InsightNarrationContext context) {
    final current = context.currentValue.round();
    final baseline = context.baselineValue.round();
    return switch (context.direction) {
      InsightDirection.lower => InsightText(
        title: '어제는 조금 조용한 하루였어요',
        body: '최근 며칠보다 이동이 적고 차분했어요.',
        evidence: '${current}m, 최근 평균 ${baseline}m',
      ),
      InsightDirection.higher => InsightText(
        title: '어제는 평소보다 많이 움직였어요',
        body: '최근 며칠보다 이동이 많은 하루였어요.',
        evidence: '${current}m, 최근 평균 ${baseline}m',
      ),
      InsightDirection.newValue => const InsightText(
        title: '이동 흐름이 새롭게 보였어요',
        body: '최근 흐름과 다른 이동 기록이 남았어요.',
        evidence: '이동 기록 변화',
      ),
    };
  }

  InsightText _visitText(InsightNarrationContext context) {
    final current = context.currentValue.round();
    final baseline = context.baselineValue.round();
    return switch (context.direction) {
      InsightDirection.lower => InsightText(
        title: '어제는 머문 곳이 적었어요',
        body: '최근 며칠보다 들른 곳이 적은 하루였어요.',
        evidence: '$current회 방문, 최근 평균 $baseline회',
      ),
      InsightDirection.higher => InsightText(
        title: '어제는 여러 곳을 들렀어요',
        body: '최근 며칠보다 머문 곳이 많은 하루였어요.',
        evidence: '$current회 방문, 최근 평균 $baseline회',
      ),
      InsightDirection.newValue => const InsightText(
        title: '방문 흐름이 새롭게 보였어요',
        body: '최근 흐름과 다른 방문 기록이 남았어요.',
        evidence: '방문 기록 변화',
      ),
    };
  }

  InsightText _newPlaceText(InsightNarrationContext context) {
    return InsightText(
      title: '새롭게 자주 머문 곳이 생겼어요',
      body: '최근 흐름에 없던 머문 곳이 기록에 남았어요.',
      evidence: '새롭게 보인 곳 ${context.currentValue.round()}곳',
    );
  }
}
