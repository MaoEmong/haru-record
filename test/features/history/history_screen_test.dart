// ignore_for_file: depend_on_referenced_packages, unused_import

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:projectapp_1/app/app.dart';
import 'package:projectapp_1/features/background/daily_insight_worker.dart';
import 'package:projectapp_1/features/settings/settings_models.dart';
import 'package:projectapp_1/features/settings/settings_repository.dart';
import 'package:projectapp_1/features/storage/app_database.dart';
import 'package:projectapp_1/features/tracking/location_event_importer.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../helpers/test_app_dependencies.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  testWidgets('empty history shows example reflection cards', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(dependencies: testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('돌아보기'));
    await tester.pumpAndSettle();

    expect(find.text('아직 재생할 하루가 없어요'), findsOneWidget);
    expect(find.text('하루가 끝나면 여기에 쌓여요'), findsOneWidget);
    expect(find.text('기록이 모이면 조용히 정리돼요'), findsOneWidget);
  });
}
