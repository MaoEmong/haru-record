class DayTimelineItem {
  const DayTimelineItem({
    required this.timeLabel,
    required this.placeLabel,
    required this.durationLabel,
    this.startedAt,
    this.endedAt,
    this.durationMinutes,
    this.latitude,
    this.longitude,
    this.isInferred = false,
  });

  final String timeLabel;
  final String placeLabel;
  final String durationLabel;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationMinutes;
  final double? latitude;
  final double? longitude;
  final bool isInferred;

  bool get canSaveAsPlace =>
      isInferred &&
      startedAt != null &&
      endedAt != null &&
      durationMinutes != null &&
      latitude != null &&
      longitude != null;
}
