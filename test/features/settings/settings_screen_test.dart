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
  testWidgets('settings screen saves tracking state', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    final trackingService = FakeTrackingService();
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: testDependencies(
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
      DailyPatternApp(dependencies: testDependencies(database)),
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
      DailyPatternApp(dependencies: testDependencies(database)),
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

  testWidgets('settings threshold edits restart active tracking', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final settingsRepository = SettingsRepository();
    final trackingService = FakeTrackingService()..started = true;
    addTearDown(database.close);
    await settingsRepository.save(
      AppSettings.defaults().copyWith(trackingEnabled: true),
    );

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: testDependencies(
          database,
          settingsRepository: settingsRepository,
          trackingService: trackingService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('movement-threshold-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('number-setting-field')),
      '50',
    );
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(trackingService.stopCount, 1);
    expect(trackingService.startCount, 1);
    expect(trackingService.lastStartedSettings?.minimumMovementMeters, 50);
  });

  testWidgets('tracking toggle explains missing location permission', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final trackingService = FakeTrackingService();
    final permissionService = FakePermissionService(locationGranted: false);
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: testDependencies(
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
    final trackingService = FakeTrackingService();
    final permissionService = FakePermissionService(locationGranted: false);
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: testDependencies(
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
    expect(
      find.byKey(const ValueKey('settings-status-breath')),
      findsOneWidget,
    );
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
      DailyPatternApp(dependencies: testDependencies(database)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-status-area')), findsOneWidget);
    expect(find.textContaining('위치 1개'), findsNothing);
    expect(find.textContaining('방문 0개'), findsOneWidget);
    expect(find.textContaining('돌아보기 0개'), findsOneWidget);
  });

  testWidgets('manual daily processing refreshes visible insight state', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    var processingRuns = 0;
    addTearDown(database.close);

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: testDependencies(
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

    expect(find.text('Now Playing'), findsOneWidget);

    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('어제 돌아보기 만들기'), 200);
    await tester.tap(find.text('어제 돌아보기 만들기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('오늘'));
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
        dependencies: testDependencies(
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
        dependencies: testDependencies(
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
        dependencies: testDependencies(
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
      DailyPatternApp(dependencies: testDependencies(database)),
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
    final permissionService = FakePermissionService(
      locationGranted: true,
      notificationGranted: false,
    );
    addTearDown(database.close);

    await settingsRepository.save(
      AppSettings.defaults().copyWith(notificationEnabled: false),
    );

    await tester.pumpWidget(
      DailyPatternApp(
        dependencies: testDependencies(
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
