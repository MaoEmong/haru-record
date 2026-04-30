// ignore_for_file: depend_on_referenced_packages

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/app/app_dependencies.dart';
import 'package:projectapp_1/app/daily_processing_service.dart';
import 'package:projectapp_1/app/startup_record_sync_service.dart';
import 'package:projectapp_1/app/tracking_reconciliation_service.dart';
import 'package:projectapp_1/app/tracking_settings_service.dart';
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

  test('assembles application services', () {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final dependencies = testDependencies(database);

    expect(dependencies, isA<AppDependencies>());
    expect(dependencies.dailyProcessingService, isA<DailyProcessingService>());
    expect(
      dependencies.startupRecordSyncService,
      isA<StartupRecordSyncService>(),
    );
    expect(
      dependencies.trackingReconciliationService,
      isA<TrackingReconciliationService>(),
    );
    expect(
      dependencies.trackingSettingsService,
      isA<TrackingSettingsService>(),
    );
  });
}
