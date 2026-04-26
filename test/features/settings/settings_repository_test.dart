import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/settings/settings_models.dart';
import 'package:projectapp_1/features/settings/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads battery-saving defaults', () async {
    final repository = SettingsRepository();
    final settings = await repository.load();

    expect(settings.trackingEnabled, isFalse);
    expect(settings.notificationEnabled, isTrue);
    expect(settings.notificationHour, 9);
    expect(settings.minimumMovementMeters, 100);
    expect(settings.minimumStayMinutes, 10);
    expect(settings.rawPointRetentionDays, 30);
  });

  test('saves and reloads settings', () async {
    final repository = SettingsRepository();
    const updated = AppSettings(
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
}
