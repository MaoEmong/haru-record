import '../analysis/daily_summary_service.dart';
import 'pattern_analysis_models.dart';

export 'pattern_analysis_models.dart';

class PatternAnalysisService {
  const PatternAnalysisService();

  List<PatternSignal> analyze(List<DailySummarySnapshot> summaries) {
    if (summaries.length < 4) return const [];
    final ordered = [...summaries]..sort((a, b) => a.date.compareTo(b.date));
    final signals = <PatternSignal>[];

    final firstDistance = ordered.first.totalDistanceMeters;
    final lastDistance = ordered.last.totalDistanceMeters;
    if (firstDistance > 0 && lastDistance < firstDistance * 0.6) {
      signals.add(
        PatternSignal(
          type: PatternSignalType.decreasingMovement,
          strength: 1 - (lastDistance / firstDistance),
          evidence:
              '${firstDistance.round()}m에서 ${lastDistance.round()}m로 줄었어요',
        ),
      );
    }
    if (firstDistance > 0 && lastDistance > firstDistance * 1.4) {
      signals.add(
        PatternSignal(
          type: PatternSignalType.increasingMovement,
          strength: (lastDistance / firstDistance) - 1,
          evidence:
              '${firstDistance.round()}m에서 ${lastDistance.round()}m로 늘었어요',
        ),
      );
    }

    final firstVisits = ordered.first.visitCount;
    final lastVisits = ordered.last.visitCount;
    if (firstVisits > 0 && lastVisits < firstVisits) {
      signals.add(
        PatternSignal(
          type: PatternSignalType.decreasingVisits,
          strength: (firstVisits - lastVisits) / firstVisits,
          evidence: '$firstVisits곳에서 $lastVisits곳으로 줄었어요',
        ),
      );
    }
    if (firstVisits > 0 && lastVisits > firstVisits) {
      signals.add(
        PatternSignal(
          type: PatternSignalType.increasingVisits,
          strength: (lastVisits - firstVisits) / firstVisits,
          evidence: '$firstVisits곳에서 $lastVisits곳으로 늘었어요',
        ),
      );
    }

    signals.sort((a, b) => b.strength.compareTo(a.strength));
    return signals.take(2).toList(growable: false);
  }
}
