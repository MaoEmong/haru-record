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
  testWidgets('empty places shows example frequent place cards', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(dependencies: testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('방문한 곳'));
    await tester.pumpAndSettle();

    expect(find.text('아직 라이브러리가 비어 있어요'), findsOneWidget);
    expect(
      find.text('오늘 기록에서 머문 곳을 저장하면 자주 간 장소와 이름 없는 곳이 이곳에 모여요.'),
      findsOneWidget,
    );
    expect(find.text('방문한 곳'), findsWidgets);
    expect(find.text('이렇게 모여요'), findsOneWidget);
    expect(find.text('자주 머문 곳'), findsOneWidget);
    expect(find.text('이름 없는 곳'), findsOneWidget);
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
      DailyPatternApp(dependencies: testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('방문한 곳'));
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
    final placeId = await database
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
      DailyPatternApp(dependencies: testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('방문한 곳'));
    await tester.pumpAndSettle();
    expect(find.text('방문한 곳'), findsWidgets);

    await tester.tap(find.byKey(ValueKey('place-card-$placeId')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('방문한 곳'), findsWidgets);

    final places = await database.select(database.placeClusters).get();
    expect(places.single.displayName, isNull);
  });
}
