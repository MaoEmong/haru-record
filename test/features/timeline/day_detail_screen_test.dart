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
  testWidgets('today detail estimates summary and flow from raw points', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 9);
    for (var i = 0; i < 8; i++) {
      await database
          .into(database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: start.add(Duration(minutes: i * 2)),
              latitude: i < 4 ? 37 : 37.01,
              longitude: 127,
              accuracy: 20,
            ),
          );
    }

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

    expect(find.text('지도 핀 2개'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('하루 요약'),
      300,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    expect(find.text('방문 0곳'), findsOneWidget);
    expect(find.textContaining('움직임'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('장소 흐름'),
      300,
      scrollable: find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first,
    );
    expect(find.text('장소 흐름'), findsOneWidget);
  });

  testWidgets('today inferred stay can be saved as a visited place', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final settingsRepository = SettingsRepository();
    addTearDown(database.close);
    await settingsRepository.save(
      AppSettings.defaults().copyWith(
        minimumMovementMeters: 50,
        minimumStayMinutes: 5,
      ),
    );
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 9);
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: start,
            latitude: 35.1596,
            longitude: 129.0602,
            accuracy: 20,
          ),
        );
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: start.add(const Duration(minutes: 8)),
            latitude: 35.15961,
            longitude: 129.06021,
            accuracy: 20,
          ),
        );

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: testDependencies(
          database,
          settingsRepository: settingsRepository,
        ),
      ),
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
    await tester.scrollUntilVisible(find.text('장소 흐름'), 300);
    await tester.tap(find.text('저장').last);
    await tester.pumpAndSettle();

    expect(find.text('이 머문 곳을 저장할까요?'), findsOneWidget);
    expect(find.byKey(const ValueKey('save-place-map')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('save-place-name-field')),
      '학원',
    );
    await tester.tap(find.text('저장').last);
    await tester.pumpAndSettle();

    final places = await database.select(database.placeClusters).get();
    final visits = await database.select(database.visits).get();
    expect(places, hasLength(1));
    expect(places.single.displayName, '학원');
    expect(places.single.visitCount, 1);
    expect(visits, hasLength(1));
    expect(visits.single.placeClusterId, places.single.id);
  });

  testWidgets('history insight opens a day detail route summary', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final date = DateTime(2026, 4, 26);
    final homeId = await database
        .into(database.placeClusters)
        .insert(
          PlaceClustersCompanion.insert(
            centerLatitude: 37,
            centerLongitude: 127,
            radiusMeters: 100,
            displayName: const Value('집 근처'),
            createdAt: date,
            updatedAt: date,
            visitCount: 1,
          ),
        );
    final cafeId = await database
        .into(database.placeClusters)
        .insert(
          PlaceClustersCompanion.insert(
            centerLatitude: 37.1,
            centerLongitude: 127.1,
            radiusMeters: 100,
            displayName: const Value('카페'),
            createdAt: date,
            updatedAt: date,
            visitCount: 1,
          ),
        );
    await database
        .into(database.dailySummaries)
        .insert(
          DailySummariesCompanion.insert(
            date: '2026-04-26',
            totalDistanceMeters: 1200,
            movingMinutes: 18,
            stationaryMinutes: 70,
            visitCount: 2,
            newPlaceCount: 1,
            longestStayPlaceId: Value(homeId),
          ),
        );
    await database
        .into(database.visits)
        .insert(
          VisitsCompanion.insert(
            placeClusterId: Value(homeId),
            startedAt: DateTime(2026, 4, 26, 9),
            endedAt: DateTime(2026, 4, 26, 10),
            durationMinutes: 60,
            representativeLatitude: 37,
            representativeLongitude: 127,
          ),
        );
    await database
        .into(database.visits)
        .insert(
          VisitsCompanion.insert(
            placeClusterId: Value(cafeId),
            startedAt: DateTime(2026, 4, 26, 14),
            endedAt: DateTime(2026, 4, 26, 14, 30),
            durationMinutes: 30,
            representativeLatitude: 37.1,
            representativeLongitude: 127.1,
          ),
        );
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

    await tester.tap(find.text('돌아보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('어제는 조금 조용한 하루였어요'));
    await tester.pumpAndSettle();

    expect(find.text('하루 자세히 보기'), findsOneWidget);
    expect(find.text('집 근처 -> 카페'), findsOneWidget);
    expect(find.text('방문 2곳'), findsOneWidget);
    expect(find.text('이동 1.2 km'), findsOneWidget);
  });

  testWidgets('day detail shows route preview from raw points', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final date = DateTime(2026, 4, 26);
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 26, 9),
            latitude: 37,
            longitude: 127,
            accuracy: 20,
          ),
        );
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 26, 9, 0, 10),
            latitude: 37.03,
            longitude: 127.03,
            accuracy: 20,
          ),
        );
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 26, 9, 0, 20),
            latitude: 37.06,
            longitude: 127.06,
            accuracy: 20,
          ),
        );
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 26, 10),
            latitude: 37.1,
            longitude: 127.1,
            accuracy: 20,
          ),
        );
    await database
        .into(database.insights)
        .insert(
          InsightsCompanion.insert(
            date: date,
            type: 'movementChange',
            severity: 'notable',
            title: '어제는 이동이 있었어요',
            body: '두 지점 사이의 흐름이 남았어요.',
            evidence: 'route',
            createdAt: date,
          ),
        );
    final routeFarPlaceId = await database
        .into(database.placeClusters)
        .insert(
          PlaceClustersCompanion.insert(
            centerLatitude: 38,
            centerLongitude: 128,
            radiusMeters: 100,
            displayName: const Value('먼 곳'),
            createdAt: date,
            updatedAt: date,
            visitCount: 1,
          ),
        );
    await database
        .into(database.visits)
        .insert(
          VisitsCompanion.insert(
            placeClusterId: Value(routeFarPlaceId),
            startedAt: DateTime(2026, 4, 26, 11),
            endedAt: DateTime(2026, 4, 26, 12),
            durationMinutes: 60,
            representativeLatitude: 38,
            representativeLongitude: 128,
          ),
        );

    await tester.pumpWidget(
      DailyPatternApp(dependencies: testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('돌아보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('어제는 이동이 있었어요'));
    await tester.pumpAndSettle();

    expect(find.text('이동 경로'), findsOneWidget);
    expect(find.text('지도 핀 3개'), findsOneWidget);
    expect(find.byKey(const ValueKey('day-route-map')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('day-route-cluster-layer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('day-route-point-cluster')),
      findsOneWidget,
    );
    expect(find.text('2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('day-route-start-marker')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('day-route-end-marker')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('day-route-visit-marker')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('day-route-map'))).height,
      220,
    );
    final routeMap = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(routeMap.options.minZoom, 3);
    expect(routeMap.options.maxZoom, 19);
    expect(routeMap.options.cameraConstraint, isA<ContainCameraLatitude>());
    expect(
      routeMap.options.interactionOptions.flags,
      isNot(InteractiveFlag.none),
    );
    expect(
      find.byKey(const ValueKey('day-route-position-marker')),
      findsNothing,
    );
    final cameraFit = routeMap.options.initialCameraFit as dynamic;
    final bounds = cameraFit.bounds as LatLngBounds;
    expect(bounds.contains(const LatLng(38, 128)), isTrue);
    expect(
      find.byKey(const ValueKey('map-snapshot-day-route-2026-04-26')),
      findsNothing,
    );
  });
}
