class AppSettings {
  AppSettings({
    required this.trackingEnabled,
    required this.notificationEnabled,
    required this.notificationHour,
    required this.notificationMinute,
    required this.minimumMovementMeters,
    required this.minimumStayMinutes,
    required this.rawPointRetentionDays,
  }) {
    RangeError.checkValueInInterval(
      notificationHour,
      0,
      23,
      'notificationHour',
    );
    RangeError.checkValueInInterval(
      notificationMinute,
      0,
      59,
      'notificationMinute',
    );
    RangeError.checkNotNegative(minimumMovementMeters, 'minimumMovementMeters');
    RangeError.checkNotNegative(minimumStayMinutes, 'minimumStayMinutes');
    RangeError.checkValueInInterval(
      rawPointRetentionDays,
      1,
      3650,
      'rawPointRetentionDays',
    );
  }

  factory AppSettings.defaults() {
    return AppSettings(
      trackingEnabled: false,
      notificationEnabled: true,
      notificationHour: 9,
      notificationMinute: 0,
      minimumMovementMeters: 100,
      minimumStayMinutes: 10,
      rawPointRetentionDays: 30,
    );
  }

  factory AppSettings.normalized({
    required bool trackingEnabled,
    required bool notificationEnabled,
    required int notificationHour,
    required int notificationMinute,
    required int minimumMovementMeters,
    required int minimumStayMinutes,
    required int rawPointRetentionDays,
  }) {
    final defaults = AppSettings.defaults();
    return AppSettings(
      trackingEnabled: trackingEnabled,
      notificationEnabled: notificationEnabled,
      notificationHour: _validRange(notificationHour, 0, 23)
          ? notificationHour
          : defaults.notificationHour,
      notificationMinute: _validRange(notificationMinute, 0, 59)
          ? notificationMinute
          : defaults.notificationMinute,
      minimumMovementMeters: minimumMovementMeters >= 0
          ? minimumMovementMeters
          : defaults.minimumMovementMeters,
      minimumStayMinutes: minimumStayMinutes >= 0
          ? minimumStayMinutes
          : defaults.minimumStayMinutes,
      rawPointRetentionDays: _validRange(rawPointRetentionDays, 1, 3650)
          ? rawPointRetentionDays
          : defaults.rawPointRetentionDays,
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

bool _validRange(int value, int min, int max) => value >= min && value <= max;
