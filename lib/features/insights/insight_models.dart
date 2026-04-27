enum InsightType {
  routineTrend,
  movementChange,
  visitChange,
  newPlace,
  longestStay,
  lowConfidence,
}

enum InsightSeverity { neutral, notable, important }

class GeneratedInsight {
  const GeneratedInsight({
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
    required this.evidence,
  });

  final InsightType type;
  final InsightSeverity severity;
  final String title;
  final String body;
  final String evidence;
}
