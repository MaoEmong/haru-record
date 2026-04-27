enum PatternSignalType {
  decreasingMovement,
  increasingMovement,
  decreasingVisits,
  increasingVisits,
}

class PatternSignal {
  const PatternSignal({
    required this.type,
    required this.strength,
    required this.evidence,
  });

  final PatternSignalType type;
  final double strength;
  final String evidence;
}
