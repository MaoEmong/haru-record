class AppSettings {
  const AppSettings({
    required this.trackingEnabled,
    required this.notificationEnabled,
    required this.notificationHour,
    required this.notificationMinute,
    required this.minimumMovementMeters,
    required this.minimumStayMinutes,
    required this.rawPointRetentionDays,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      trackingEnabled: false,
      notificationEnabled: true,
      notificationHour: 9,
      notificationMinute: 0,
      minimumMovementMeters: 100,
      minimumStayMinutes: 10,
      rawPointRetentionDays: 30,
    );
  }

  final bool trackingEnabled;
  final bool notificationEnabled;
  final int notificationHour;
  final int notificationMinute;
  final int minimumMovementMeters;
  final int minimumStayMinutes;
  final int rawPointRetentionDays;

  AppSettings copyWith({
    bool? trackingEnabled,
    bool? notificationEnabled,
    int? notificationHour,
    int? notificationMinute,
    int? minimumMovementMeters,
    int? minimumStayMinutes,
    int? rawPointRetentionDays,
  }) {
    return AppSettings(
      trackingEnabled: trackingEnabled ?? this.trackingEnabled,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
      minimumMovementMeters:
          minimumMovementMeters ?? this.minimumMovementMeters,
      minimumStayMinutes: minimumStayMinutes ?? this.minimumStayMinutes,
      rawPointRetentionDays:
          rawPointRetentionDays ?? this.rawPointRetentionDays,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.trackingEnabled == trackingEnabled &&
        other.notificationEnabled == notificationEnabled &&
        other.notificationHour == notificationHour &&
        other.notificationMinute == notificationMinute &&
        other.minimumMovementMeters == minimumMovementMeters &&
        other.minimumStayMinutes == minimumStayMinutes &&
        other.rawPointRetentionDays == rawPointRetentionDays;
  }

  @override
  int get hashCode => Object.hash(
        trackingEnabled,
        notificationEnabled,
        notificationHour,
        notificationMinute,
        minimumMovementMeters,
        minimumStayMinutes,
        rawPointRetentionDays,
      );
}
