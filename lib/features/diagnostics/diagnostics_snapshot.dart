class DiagnosticsSnapshot {
  const DiagnosticsSnapshot({
    required this.locationPointCount,
    required this.visitCount,
    required this.reflectionCount,
    required this.lastPointTimeLabel,
  });

  final int locationPointCount;
  final int visitCount;
  final int reflectionCount;
  final String lastPointTimeLabel;
}
