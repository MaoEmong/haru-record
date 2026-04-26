import 'package:shared_preferences/shared_preferences.dart';

import 'settings_models.dart';

class SettingsRepository {
  SettingsRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _trackingEnabled = 'trackingEnabled';
  static const _notificationEnabled = 'notificationEnabled';
  static const _notificationHour = 'notificationHour';
  static const _notificationMinute = 'notificationMinute';
  static const _minimumMovementMeters = 'minimumMovementMeters';
  static const _minimumStayMinutes = 'minimumStayMinutes';
  static const _rawPointRetentionDays = 'rawPointRetentionDays';

  final SharedPreferencesAsync _preferences;

  Future<AppSettings> load() async {
    final defaults = AppSettings.defaults();
    return AppSettings.normalized(
      trackingEnabled:
          await _preferences.getBool(_trackingEnabled) ??
          defaults.trackingEnabled,
      notificationEnabled:
          await _preferences.getBool(_notificationEnabled) ??
          defaults.notificationEnabled,
      notificationHour:
          await _preferences.getInt(_notificationHour) ??
          defaults.notificationHour,
      notificationMinute:
          await _preferences.getInt(_notificationMinute) ??
          defaults.notificationMinute,
      minimumMovementMeters:
          await _preferences.getInt(_minimumMovementMeters) ??
          defaults.minimumMovementMeters,
      minimumStayMinutes:
          await _preferences.getInt(_minimumStayMinutes) ??
          defaults.minimumStayMinutes,
      rawPointRetentionDays:
          await _preferences.getInt(_rawPointRetentionDays) ??
          defaults.rawPointRetentionDays,
    );
  }

  Future<void> save(AppSettings settings) async {
    await _preferences.setBool(_trackingEnabled, settings.trackingEnabled);
    await _preferences.setBool(
      _notificationEnabled,
      settings.notificationEnabled,
    );
    await _preferences.setInt(_notificationHour, settings.notificationHour);
    await _preferences.setInt(_notificationMinute, settings.notificationMinute);
    await _preferences.setInt(
      _minimumMovementMeters,
      settings.minimumMovementMeters,
    );
    await _preferences.setInt(_minimumStayMinutes, settings.minimumStayMinutes);
    await _preferences.setInt(
      _rawPointRetentionDays,
      settings.rawPointRetentionDays,
    );
  }
}
