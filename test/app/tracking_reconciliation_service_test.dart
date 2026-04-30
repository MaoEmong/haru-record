// ignore_for_file: depend_on_referenced_packages

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/settings/settings_models.dart';
import 'package:projectapp_1/features/settings/settings_repository.dart';
import 'package:projectapp_1/features/storage/app_database.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../helpers/test_app_dependencies.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  test('restarts native tracking when saved setting is enabled', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final settingsRepository = SettingsRepository();
    final trackingService = FakeTrackingService();
    await settingsRepository.save(
      AppSettings.defaults().copyWith(trackingEnabled: true),
    );
    final dependencies = testDependencies(
      database,
      settingsRepository: settingsRepository,
      trackingService: trackingService,
    );

    await dependencies.reconcileTrackingState();

    expect(trackingService.startCount, 1);
  });

  test('does not restart native tracking when it is already running', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final settingsRepository = SettingsRepository();
    final trackingService = FakeTrackingService(started: true);
    await settingsRepository.save(
      AppSettings.defaults().copyWith(trackingEnabled: true),
    );
    final dependencies = testDependencies(
      database,
      settingsRepository: settingsRepository,
      trackingService: trackingService,
    );

    await dependencies.reconcileTrackingState();

    expect(trackingService.startCount, 0);
  });
}
