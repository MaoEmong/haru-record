// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/settings/settings_models.dart';
import 'package:projectapp_1/features/settings/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('loads battery-saving defaults', () async {
    final repository = SettingsRepository();
    final settings = await repository.load();

    expect(settings.trackingEnabled, isFalse);
    expect(settings.notificationEnabled, isTrue);
    expect(settings.notificationHour, 9);
    expect(settings.notificationMinute, 0);
    expect(settings.minimumMovementMeters, 100);
    expect(settings.minimumStayMinutes, 10);
    expect(settings.rawPointRetentionDays, 30);
  });

  test('saves and reloads settings', () async {
    final repository = SettingsRepository();
    final updated = AppSettings(
      trackingEnabled: true,
      notificationEnabled: false,
      notificationHour: 8,
      notificationMinute: 30,
      minimumMovementMeters: 150,
      minimumStayMinutes: 15,
      rawPointRetentionDays: 14,
    );

    await repository.save(updated);
    final loaded = await repository.load();

    expect(loaded, updated);
  });

  test('normalizes invalid persisted settings back to defaults', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setInt('notificationHour', 99);
    await preferences.setInt('notificationMinute', -1);
    await preferences.setInt('minimumMovementMeters', -100);
    await preferences.setInt('minimumStayMinutes', -10);
    await preferences.setInt('rawPointRetentionDays', 0);

    final repository = SettingsRepository(preferences: preferences);
    final loaded = await repository.load();

    expect(loaded.notificationHour, 9);
    expect(loaded.notificationMinute, 0);
    expect(loaded.minimumMovementMeters, 100);
    expect(loaded.minimumStayMinutes, 10);
    expect(loaded.rawPointRetentionDays, 30);
  });

  test('rejects invalid AppSettings values', () {
    expect(
      () => AppSettings(
        trackingEnabled: false,
        notificationEnabled: true,
        notificationHour: 24,
        notificationMinute: 0,
        minimumMovementMeters: 100,
        minimumStayMinutes: 10,
        rawPointRetentionDays: 30,
      ),
      throwsRangeError,
    );
  });
}
