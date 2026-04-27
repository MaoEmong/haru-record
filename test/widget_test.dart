// ignore_for_file: depend_on_referenced_packages

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/app/app.dart';
import 'package:projectapp_1/app/app_dependencies.dart';
import 'package:projectapp_1/features/background/daily_insight_worker.dart';
import 'package:projectapp_1/features/notifications/notification_service.dart';
import 'package:projectapp_1/features/permissions/app_permission_service.dart';
import 'package:projectapp_1/features/settings/settings_models.dart';
import 'package:projectapp_1/features/settings/settings_repository.dart';
import 'package:projectapp_1/features/storage/app_maintenance_service.dart';
import 'package:projectapp_1/features/storage/app_database.dart';
import 'package:projectapp_1/features/tracking/location_event_importer.dart';
import 'package:projectapp_1/features/tracking/location_tracking_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

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
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    expect(find.text('오늘'), findsWidgets);
    expect(find.text('돌아보기'), findsOneWidget);
    expect(find.text('자주 간 곳'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
    expect(find.text('아직 돌아볼 하루가 없어요'), findsOneWidget);
  });

  testWidgets('app uses the bundled Kyobo handwriting font', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      materialApp.theme?.textTheme.bodyMedium?.fontFamily,
      'KyoboHandwriting',
    );
    expect(materialApp.theme?.textTheme.bodyMedium?.fontSize, 15);
    expect(materialApp.theme?.textTheme.titleLarge?.fontSize, 23);
  });

  testWidgets('home summarizes records from today', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    expect(find.text('1.2km'), findsOneWidget);
    expect(find.text('2곳'), findsOneWidget);
    expect(find.text('18분'), findsOneWidget);
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
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    expect(find.text('1.1km'), findsOneWidget);
    expect(find.text('0곳'), findsOneWidget);
    expect(find.text('12분'), findsOneWidget);
    expect(find.text('최근 위치 기록'), findsOneWidget);
  });

  testWidgets('app imports pending native location events on startup', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    var imported = false;
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: _testDependencies(
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
    await tester.tap(find.text('오늘 기록'));
    await tester.pumpAndSettle();

    expect(find.text('위치 기록 1개'), findsOneWidget);
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
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    expect(find.text('오늘의 흐름'), findsOneWidget);
    expect(find.text('집 근처'), findsOneWidget);
    expect(find.text('1시간 10분 머문 곳'), findsOneWidget);
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
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -140));
    await tester.pumpAndSettle();
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
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('오늘 기록'));
    await tester.pumpAndSettle();

    expect(find.text('오늘 기록'), findsWidgets);
    expect(find.text('오늘 기록중인 위치'), findsOneWidget);
    expect(find.text('위치 기록 1개'), findsOneWidget);
    expect(find.textContaining('37.5665'), findsOneWidget);
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
              latitude: 37 + (i * 0.001),
              longitude: 127,
              accuracy: 20,
            ),
          );
    }

    await tester.pumpWidget(
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('오늘 기록'));
    await tester.pumpAndSettle();

    expect(find.text('위치 기록 8개'), findsWidgets);
    await tester.scrollUntilVisible(find.text('하루 요약'), 300);
    expect(find.text('방문 0곳'), findsOneWidget);
    expect(find.text('움직임 14분'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('최근 위치 기록'), 300);
    expect(find.text('최근 위치 기록'), findsOneWidget);
    expect(find.textContaining('위치 기록 8개 · 머문 곳은 판단 중'), findsOneWidget);
  });

  testWidgets('empty history shows example reflection cards', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('돌아보기'));
    await tester.pumpAndSettle();

    expect(find.text('이런 식으로 하루가 정리돼요'), findsOneWidget);
    expect(find.text('예시'), findsWidgets);
    expect(find.text('어제는 조금 조용한 하루였어요'), findsOneWidget);
  });

  testWidgets('empty places shows example frequent place cards', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('자주 간 곳'));
    await tester.pumpAndSettle();

    expect(find.text('자주 머문 곳은 이렇게 보여요'), findsOneWidget);
    expect(find.text('집 근처'), findsOneWidget);
    expect(find.text('3번 머문 곳'), findsOneWidget);
  });

  testWidgets('frequent places show map context for each place', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime(2026, 4, 27);
    final homeId = await database
        .into(database.placeClusters)
        .insert(
          PlaceClustersCompanion.insert(
            centerLatitude: 37.5665,
            centerLongitude: 126.978,
            radiusMeters: 100,
            displayName: const Value('집 근처'),
            createdAt: now,
            updatedAt: now,
            visitCount: 4,
          ),
        );
    final cafeId = await database
        .into(database.placeClusters)
        .insert(
          PlaceClustersCompanion.insert(
            centerLatitude: 37.57,
            centerLongitude: 126.982,
            radiusMeters: 80,
            displayName: const Value('카페'),
            createdAt: now,
            updatedAt: now,
            visitCount: 2,
          ),
        );

    await tester.pumpWidget(
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('자주 간 곳'));
    await tester.pumpAndSettle();

    expect(find.byKey(ValueKey('place-map-$homeId')), findsOneWidget);
    expect(find.byKey(ValueKey('place-map-$cafeId')), findsOneWidget);
    final homeMap = tester.widget<FlutterMap>(
      find.byKey(ValueKey('place-map-$homeId')),
    );
    expect(homeMap.options.initialZoom, 16);
    expect(homeMap.options.interactionOptions.flags, InteractiveFlag.none);
    expect(find.byKey(ValueKey('map-snapshot-place-$homeId')), findsOneWidget);
  });

  testWidgets('canceling rename for an unnamed place keeps the app stable', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime(2026, 4, 27);
    await database
        .into(database.placeClusters)
        .insert(
          PlaceClustersCompanion.insert(
            centerLatitude: 37,
            centerLongitude: 127,
            radiusMeters: 100,
            createdAt: now,
            updatedAt: now,
            visitCount: 1,
          ),
        );

    await tester.pumpWidget(
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('자주 간 곳'));
    await tester.pumpAndSettle();
    expect(find.text('이름을 정하지 않은 곳'), findsOneWidget);

    await tester.tap(find.text('이름을 정하지 않은 곳'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('이름을 정하지 않은 곳'), findsOneWidget);

    final places = await database.select(database.placeClusters).get();
    expect(places.single.displayName, isNull);
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
      DailyPatternApp(dependencies: _testDependencies(database)),
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

    await tester.pumpWidget(
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('돌아보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('어제는 이동이 있었어요'));
    await tester.pumpAndSettle();

    expect(find.text('이동 경로'), findsOneWidget);
    expect(find.text('기록 지점 2개'), findsOneWidget);
    expect(find.byKey(const ValueKey('day-route-map')), findsOneWidget);
    final routeMap = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(routeMap.options.interactionOptions.flags, InteractiveFlag.none);
    expect(
      find.byKey(const ValueKey('map-snapshot-day-route-2026-04-26')),
      findsOneWidget,
    );
  });

  testWidgets('settings screen saves tracking state', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    final trackingService = _FakeTrackingService();
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: _testDependencies(
          database,
          trackingService: trackingService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tracking-switch')));
    await tester.pumpAndSettle();

    expect(trackingService.started, isTrue);
    expect(find.text('오늘의 흐름을 기록하고 있어요'), findsOneWidget);
  });

  testWidgets('settings explains local privacy and battery behavior', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('기록은 이 기기에만 저장돼요'), findsOneWidget);
    expect(find.text('움직임이 있을 때 중심으로 살펴 배터리 사용을 줄여요'), findsOneWidget);
  });

  testWidgets('settings screen edits thresholds and notification time', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('movement-threshold-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('number-setting-field')),
      '250',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('stay-threshold-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('number-setting-field')),
      '20',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('retention-days-edit')),
      300,
    );
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('retention-days-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('number-setting-field')),
      '14',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('notification-time-edit')),
      300,
    );
    await tester.drag(find.byType(Scrollable).last, const Offset(0, 120));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('notification-time-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('hour-setting-field')),
      '8',
    );
    await tester.enterText(
      find.byKey(const ValueKey('minute-setting-field')),
      '30',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('250 m'), findsOneWidget);
    expect(find.text('20분'), findsOneWidget);
    expect(find.text('14일'), findsOneWidget);
    expect(find.text('08:30'), findsOneWidget);
  });

  testWidgets('tracking toggle explains missing location permission', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final trackingService = _FakeTrackingService();
    final permissionService = _FakePermissionService(locationGranted: false);
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: _testDependencies(
          database,
          trackingService: trackingService,
          permissionService: permissionService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tracking-switch')));
    await tester.pumpAndSettle();

    expect(permissionService.requestedLocation, isTrue);
    expect(trackingService.started, isFalse);
    expect(find.text('하루를 기록하려면 위치 권한이 필요해요'), findsOneWidget);
  });

  testWidgets('settings status message stays in the fixed notice area', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final trackingService = _FakeTrackingService();
    final permissionService = _FakePermissionService(locationGranted: false);
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: _testDependencies(
          database,
          trackingService: trackingService,
          permissionService: permissionService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();

    final before = tester.getTopLeft(
      find.byKey(const ValueKey('movement-threshold-edit')),
    );

    await tester.tap(find.byKey(const ValueKey('tracking-switch')));
    await tester.pumpAndSettle();

    final after = tester.getTopLeft(
      find.byKey(const ValueKey('movement-threshold-edit')),
    );

    expect(before.dy, after.dy);
    expect(find.byKey(const ValueKey('settings-status-area')), findsOneWidget);
    expect(find.text('하루를 기록하려면 위치 권한이 필요해요'), findsOneWidget);
  });

  testWidgets('settings shows diagnostics in the fixed notice area', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 27, 9),
            latitude: 37,
            longitude: 127,
            accuracy: 20,
          ),
        );

    await tester.pumpWidget(
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('settings-diagnostics-summary')),
      findsOneWidget,
    );
    expect(find.textContaining('위치 1개'), findsOneWidget);
  });

  testWidgets('manual daily processing refreshes visible insight state', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    var processingRuns = 0;
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: _testDependencies(
          database,
          runDailyProcessingNow: () async {
            processingRuns++;
            await database
                .into(database.insights)
                .insert(
                  InsightsCompanion.insert(
                    date: DateTime(2026, 4, 27),
                    type: 'movementChange',
                    severity: 'notable',
                    title: '어제는 조금 조용한 하루였어요',
                    body: '최근 며칠보다 이동이 적고 차분했어요.',
                    evidence: '100m 대 최근 평균 400m',
                    createdAt: DateTime(2026, 4, 27, 9),
                  ),
                );
            return const DailyProcessingResult(
              outcome: DailyProcessingOutcome.createdReflection,
              totalPointCount: 2,
              yesterdayPointCount: 2,
              createdReflectionCount: 1,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('아직 돌아볼 하루가 없어요'), findsOneWidget);

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('어제 돌아보기 만들기'), 200);
    await tester.tap(find.text('어제 돌아보기 만들기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('오늘'));
    await tester.pumpAndSettle();

    expect(processingRuns, 1);
    expect(find.text('어제는 조금 조용한 하루였어요'), findsOneWidget);
  });

  testWidgets('manual daily processing explains when there is no record yet', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: _testDependencies(
          database,
          runDailyProcessingNow: () async {
            return const DailyProcessingResult(
              outcome: DailyProcessingOutcome.noRawRecords,
              totalPointCount: 0,
              yesterdayPointCount: 0,
              createdReflectionCount: 0,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('어제 돌아보기 만들기'), 200);
    await tester.tap(find.text('어제 돌아보기 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('아직 돌아볼 기록이 없어요'), findsOneWidget);
  });

  testWidgets('manual daily processing explains when yesterday has no record', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: _testDependencies(
          database,
          runDailyProcessingNow: () async {
            return const DailyProcessingResult(
              outcome: DailyProcessingOutcome.noYesterdayRecords,
              totalPointCount: 3,
              yesterdayPointCount: 0,
              createdReflectionCount: 0,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('어제 돌아보기 만들기'), 200);
    await tester.tap(find.text('어제 돌아보기 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('어제 기록이 아직 없어요. 오늘 기록은 내일 돌아볼 수 있어요'), findsOneWidget);
  });

  testWidgets('manual daily processing explains when no highlight was found', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: _testDependencies(
          database,
          runDailyProcessingNow: () async {
            return const DailyProcessingResult(
              outcome: DailyProcessingOutcome.noHighlights,
              totalPointCount: 4,
              yesterdayPointCount: 4,
              createdReflectionCount: 0,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('어제 돌아보기 만들기'), 200);
    await tester.tap(find.text('어제 돌아보기 만들기'));
    await tester.pumpAndSettle();

    expect(find.text('어제 기록은 봤지만 특별한 변화는 없었어요'), findsOneWidget);
  });

  testWidgets('debug seed supports device validation of yesterday reflection', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: _testDependencies(
          database,
          showDebugValidationTools: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('검증용 어제 기록 넣기'), 200);
    await tester.tap(find.text('검증용 어제 기록 넣기'));
    await tester.pumpAndSettle();

    final seededPoints = await database.select(database.locationPoints).get();
    expect(seededPoints, hasLength(2));

    await tester.scrollUntilVisible(find.text('어제 돌아보기 만들기'), 200);
    await tester.tap(find.text('어제 돌아보기 만들기'));
    await tester.pumpAndSettle();

    final visits = await database.select(database.visits).get();
    final insights = await database.select(database.insights).get();
    expect(visits, hasLength(1));
    expect(insights, isNotEmpty);
  });

  testWidgets('settings cleanup removes raw points but keeps insights', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 1, 1),
            latitude: 37,
            longitude: 127,
            accuracy: 20,
          ),
        );
    await database
        .into(database.insights)
        .insert(
          InsightsCompanion.insert(
            date: DateTime(2026, 4, 27),
            type: 'movementChange',
            severity: 'notable',
            title: '기존 돌아보기',
            body: '원본 정리 후에도 유지됩니다.',
            evidence: '시드 데이터',
            createdAt: DateTime(2026, 4, 27),
          ),
        );

    await tester.pumpWidget(
      DailyPatternApp(dependencies: _testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('delete-raw-points-button')),
      500,
    );
    await tester.tap(find.byKey(const ValueKey('delete-raw-points-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    final points = await database.select(database.locationPoints).get();
    final insights = await database.select(database.insights).get();
    expect(points, isEmpty);
    expect(insights, hasLength(1));
    expect(find.text('자세한 위치 기록을 비웠어요'), findsOneWidget);
  });

  testWidgets('notification toggle stays off when permission is denied', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final settingsRepository = SettingsRepository();
    final permissionService = _FakePermissionService(
      locationGranted: true,
      notificationGranted: false,
    );
    addTearDown(database.close);

    await settingsRepository.save(
      AppSettings.defaults().copyWith(notificationEnabled: false),
    );

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: _testDependencies(
          database,
          settingsRepository: settingsRepository,
          permissionService: permissionService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('notification-switch')),
      200,
    );
    await tester.drag(find.byType(Scrollable).last, const Offset(0, 160));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('notification-switch')));
    await tester.pumpAndSettle();

    final settings = await settingsRepository.load();
    expect(permissionService.requestedNotification, isTrue);
    expect(settings.notificationEnabled, isFalse);
    expect(find.text('돌아보기 알림을 받으려면 알림 권한이 필요해요'), findsOneWidget);
  });
}

AppDependencies _testDependencies(
  AppDatabase database, {
  SettingsRepository? settingsRepository,
  _FakeTrackingService? trackingService,
  _FakePermissionService? permissionService,
  Future<LocationEventImportResult> Function()? importPendingEvents,
  Future<DailyProcessingResult> Function()? runDailyProcessingNow,
  bool showDebugValidationTools = false,
}) {
  final notificationAdapter = _FakeNotificationAdapter();
  return AppDependencies(
    database: database,
    settingsRepository: settingsRepository ?? SettingsRepository(),
    trackingService: trackingService ?? _FakeTrackingService(),
    notificationService: NotificationService(notificationAdapter),
    permissionService:
        permissionService ?? _FakePermissionService(locationGranted: true),
    maintenanceService: AppMaintenanceService(database),
    importPendingEvents:
        importPendingEvents ??
        () async =>
            const LocationEventImportResult(importedCount: 0, skippedCount: 0),
    showDebugValidationTools: showDebugValidationTools,
    runDailyProcessingOverride: runDailyProcessingNow,
  );
}

class _FakeTrackingService implements LocationTrackingService {
  bool started = false;

  @override
  Future<bool> isTracking() async => started;

  @override
  Future<void> startTracking(AppSettings settings) async {
    started = true;
  }

  @override
  Future<void> stopTracking() async {
    started = false;
  }
}

class _FakePermissionService implements AppPermissionService {
  _FakePermissionService({
    required this.locationGranted,
    this.notificationGranted = true,
  });

  bool locationGranted;
  bool notificationGranted;
  bool requestedLocation = false;
  bool requestedNotification = false;

  @override
  Future<bool> ensureLocationTrackingPermission() async {
    requestedLocation = true;
    return locationGranted;
  }

  @override
  Future<bool> ensureNotificationPermission() async {
    requestedNotification = true;
    return notificationGranted;
  }
}

class _FakeNotificationAdapter implements NotificationAdapter {
  @override
  Future<void> cancel(int id) async {}

  @override
  Future<bool?> requestPermission() async => true;

  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {}
}
