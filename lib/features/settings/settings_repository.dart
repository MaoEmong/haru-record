import 'package:shared_preferences/shared_preferences.dart';

import 'settings_models.dart';

class SettingsRepository {
  static const _trackingEnabled = 'trackingEnabled';
  static const _notificationEnabled = 'notificationEnabled';
  static const _notificationHour = 'notificationHour';
  static const _notificationMinute = 'notificationMinute';
  static const _minimumMovementMeters = 'minimumMovementMeters';
  static const _minimumStayMinutes = 'minimumStayMinutes';
  static const _rawPointRetentionDays = 'rawPointRetentionDays';

  Future<AppSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final defaults = AppSettings.defaults();
    return AppSettings(
      trackingEnabled:
          preferences.getBool(_trackingEnabled) ?? defaults.trackingEnabled,
      notificationEnabled: preferences.getBool(_notificationEnabled) ??
          defaults.notificationEnabled,
      notificationHour:
          preferences.getInt(_notificationHour) ?? defaults.notificationHour,
      notificationMinute: preferences.getInt(_notificationMinute) ??
          defaults.notificationMinute,
      minimumMovementMeters: preferences.getInt(_minimumMovementMeters) ??
          defaults.minimumMovementMeters,
      minimumStayMinutes: preferences.getInt(_minimumStayMinutes) ??
          defaults.minimumStayMinutes,
      rawPointRetentionDays: preferences.getInt(_rawPointRetentionDays) ??
          defaults.rawPointRetentionDays,
    );
  }

  Future<void> save(AppSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_trackingEnabled, settings.trackingEnabled);
    await preferences.setBool(
      _notificationEnabled,
      settings.notificationEnabled,
    );
    await preferences.setInt(_notificationHour, settings.notificationHour);
    await preferences.setInt(_notificationMinute, settings.notificationMinute);
    await preferences.setInt(
      _minimumMovementMeters,
      settings.minimumMovementMeters,
    );
    await preferences.setInt(_minimumStayMinutes, settings.minimumStayMinutes);
    await preferences.setInt(
      _rawPointRetentionDays,
      settings.rawPointRetentionDays,
    );
  }
}
