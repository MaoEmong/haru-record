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

import '../helpers/test_app_dependencies.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  testWidgets('shows the daily pattern app shell', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(dependencies: testDependencies(database)),
    );
    await tester.pumpAndSettle();

    expect(find.text('오늘'), findsWidgets);
    expect(find.text('돌아보기'), findsOneWidget);
    expect(find.text('방문한 곳'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    expect(find.text('Now Playing'), findsOneWidget);
  });

  testWidgets('asks before exiting from the Android back button', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(dependencies: testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('앱을 종료할까요?'), findsOneWidget);
    expect(find.text('계속 사용'), findsOneWidget);
    expect(find.text('종료'), findsOneWidget);

    await tester.tap(find.text('계속 사용'));
    await tester.pumpAndSettle();

    expect(find.text('앱을 종료할까요?'), findsNothing);
    expect(find.text('오늘'), findsWidgets);
  });

  testWidgets('app uses the default platform font with app text sizing', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(dependencies: testDependencies(database)),
    );
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      materialApp.theme?.textTheme.bodyMedium?.fontFamily,
      isNot('KyoboHandwriting'),
    );
    expect(materialApp.theme?.textTheme.bodyMedium?.fontSize, 15);
    expect(materialApp.theme?.textTheme.titleLarge?.fontSize, 23);
  });

  testWidgets('app imports pending native location events on startup', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    var imported = false;
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: testDependencies(
          database,
          importPendingEvents: () async {
            imported = true;
            await database
                .into(database.locationPoints)
                .insert(
                  LocationPointsCompanion.insert(
                    timestamp: DateTime.now(),
                    latitude: 37,
                    longitude: 127,
                    accuracy: 20,
                  ),
                );
            return const LocationEventImportResult(
              importedCount: 1,
              skippedCount: 0,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(imported, isTrue);
    final todayControl = find.byKey(
      const ValueKey('home-open-today-records-control'),
    );
    await tester.scrollUntilVisible(
      todayControl,
      300,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.tap(todayControl);
    await tester.pumpAndSettle();

    expect(find.text('지도 핀 1개'), findsOneWidget);
  });
}
