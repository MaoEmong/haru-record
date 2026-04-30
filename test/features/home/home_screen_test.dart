// ignore_for_file: depend_on_referenced_packages, unused_import

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:projectapp_1/app/app.dart';
import 'package:projectapp_1/core/time/date_key.dart';
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
  testWidgets('home summarizes records from today', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now();
    final today = dateKey(now);
    await database
        .into(database.dailySummaries)
        .insert(
          DailySummariesCompanion.insert(
            date: today,
            totalDistanceMeters: 1200,
            movingMinutes: 18,
            stationaryMinutes: 42,
            visitCount: 2,
            newPlaceCount: 1,
          ),
        );

    await tester.pumpWidget(
      DailyPatternApp(dependencies: testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('1.2km'),
      300,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    expect(find.textContaining('1.2km'), findsOneWidget);
    expect(find.textContaining('2곳'), findsWidgets);
    expect(find.textContaining('분'), findsNothing);
  });

  testWidgets('home estimates today stats from raw points before processing', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 9);
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: start,
            latitude: 37,
            longitude: 127,
            accuracy: 20,
          ),
        );
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: start.add(const Duration(minutes: 12)),
            latitude: 37.01,
            longitude: 127,
            accuracy: 20,
          ),
        );

    await tester.pumpWidget(
      DailyPatternApp(dependencies: testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('1.1km'),
      300,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    expect(find.textContaining('1.1km'), findsOneWidget);
    expect(find.textContaining('0곳'), findsWidgets);
    expect(find.textContaining('분'), findsNothing);
  });

  testWidgets('home shows a compact timeline preview when visits exist', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now();
    final placeId = await database
        .into(database.placeClusters)
        .insert(
          PlaceClustersCompanion.insert(
            centerLatitude: 37,
            centerLongitude: 127,
            radiusMeters: 100,
            displayName: const Value('집 근처'),
            createdAt: now,
            updatedAt: now,
            visitCount: 1,
          ),
        );
    await database
        .into(database.visits)
        .insert(
          VisitsCompanion.insert(
            placeClusterId: Value(placeId),
            startedAt: DateTime(now.year, now.month, now.day, 9),
            endedAt: DateTime(now.year, now.month, now.day, 10, 10),
            durationMinutes: 70,
            representativeLatitude: 37,
            representativeLongitude: 127,
          ),
        );

    await tester.pumpWidget(
      DailyPatternApp(dependencies: testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('오늘 방문한 곳'),
      300,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    expect(find.text('오늘 방문한 곳'), findsOneWidget);
    expect(find.text('집 근처'), findsWidgets);
    expect(find.text('머문 기록'), findsWidgets);
  });

  testWidgets('home recent reflection opens the reflection detail', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final date = DateTime(2026, 4, 26);
    await database
        .into(database.insights)
        .insert(
          InsightsCompanion.insert(
            date: date,
            type: 'movementChange',
            severity: 'notable',
            title: '어제는 조금 조용한 하루였어요',
            body: '최근 며칠보다 이동이 적고 차분했어요.',
            evidence: '1200m',
            createdAt: date,
          ),
        );
    await tester.pumpWidget(
      DailyPatternApp(dependencies: testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('어제는 조금 조용한 하루였어요'),
      400,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.tap(find.text('어제는 조금 조용한 하루였어요'));
    await tester.pumpAndSettle();

    expect(find.text('하루 자세히 보기'), findsOneWidget);
    expect(find.text('2026-04-26'), findsOneWidget);
    expect(find.text('최근 며칠보다 이동이 적고 차분했어요.'), findsOneWidget);
  });

  testWidgets('home today record opens current day records', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now();
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: now,
            latitude: 37.5665,
            longitude: 126.978,
            accuracy: 20,
          ),
        );

    await tester.pumpWidget(
      DailyPatternApp(dependencies: testDependencies(database)),
    );
    await tester.pumpAndSettle();

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

    expect(find.text('오늘 기록'), findsWidgets);
    expect(find.text('오늘 기록중인 위치'), findsNothing);
    expect(find.text('지도 핀 1개'), findsOneWidget);
    expect(find.textContaining('37.5665'), findsNothing);
  });
}
