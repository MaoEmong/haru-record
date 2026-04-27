# Original Vision Gap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the largest gaps between the Notion spec "일상 패턴 자동 분석 & 인사이트 앱" and the current Flutter/Android MVP.

**Architecture:** Keep the existing local-first architecture: Android foreground location service writes raw events, Flutter imports into Drift, daily worker derives visits/summaries/insights, UI reads from Drift. Add missing product value in thin vertical slices: first prove real-device automation, then add route visualization, then deepen pattern analysis, then improve narrative/notification delivery.

**Tech Stack:** Flutter, Dart, Drift/SQLite, Android Kotlin foreground service, Workmanager, flutter_local_notifications, permission_handler, widget/unit tests.

---

## Current Gap Summary

The current project already implements the core data pipeline: background-ish location collection, local event import, visit clustering, place clusters, daily summaries, rule-based insights, local notifications, history, today records, settings, diagnostics, and local deletion.

The Notion vision is broader: "사용자는 아무것도 하지 않지만, 앱은 사용자의 하루를 기록하고 해석하여 의미 있는 인사이트를 제공한다." The largest gaps are:

- Real-device proof that collection, daily processing, and 9 AM notification work without manual intervention.
- Map-based day route visualization.
- Pattern analysis beyond simple distance/visit/new-place deltas.
- AI-style natural wording, while keeping logic-based analysis.
- Product polish: app name, final Korean copy, privacy/battery trust messaging, and fewer debug-like controls.

---

## File Structure

### Existing Files To Modify

- `pubspec.yaml`
  - Registers the custom font in `assets/KyoboHandwriting2025lyb.ttf`.

- `lib/app/app.dart`
  - Applies the registered font family to `ThemeData`.

- `lib/features/background/daily_insight_worker.dart`
  - Owns daily import, visit detection, summary generation, insight persistence, notification scheduling.

- `lib/features/analysis/daily_summary_service.dart`
  - Owns daily metrics: distance, moving minutes, stationary minutes, visit count, new places, longest stay.

- `lib/features/insights/insight_generation_service.dart`
  - Owns rule-based insight candidate generation and ranking.

- `lib/features/insights/insight_narrator.dart`
  - Owns human-facing insight copy.

- `lib/features/timeline/day_detail_screen.dart`
  - Owns day detail UI. This is the best place to add route/map visualization.

- `lib/features/timeline/day_timeline_repository.dart`
  - Owns day visits with place labels. Extend this to expose route points or route segments.

- `lib/features/home/home_screen.dart`
  - Owns today overview and latest reflection entry points.

- `lib/features/history/history_screen.dart`
  - Owns insight history list.

- `lib/features/settings/settings_screen.dart`
  - Owns controls, diagnostics, privacy deletion, debug validation tools.

- `android/app/src/main/kotlin/com/example/projectapp_1/tracking/LocationTrackingService.kt`
  - Owns native foreground service location collection and raw event writing.

- `android/app/src/main/AndroidManifest.xml`
  - Owns Android permissions and service declarations.

### New Files To Create

- `lib/features/timeline/day_route_models.dart`
  - Route visualization models that do not expose raw database rows to UI widgets.

- `lib/features/timeline/day_route_repository.dart`
  - Loads same-day route points and visit overlays for day detail.

- `test/features/timeline/day_route_repository_test.dart`
  - Tests route point ordering, filtering, and visit labels.

- `lib/features/insights/pattern_analysis_models.dart`
  - Models for trend/repetition signals.

- `lib/features/insights/pattern_analysis_service.dart`
  - Detects weekly trends and repeated routines from daily summaries and visits.

- `test/features/insights/pattern_analysis_service_test.dart`
  - Tests trend and repeated-place detection.

- `docs/validation/android-device-validation.md`
  - Manual validation checklist for real Android devices.

---

## Phase 0: Apply Custom App Font

### Task 0: Register And Apply Kyobo Font

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/app/app.dart`
- Test: `test/widget_test.dart`
- Asset: `assets/KyoboHandwriting2025lyb.ttf`

- [ ] **Step 1: Write the failing widget test**

Add to `test/widget_test.dart`:

```dart
testWidgets('app uses the bundled Kyobo handwriting font', (tester) async {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);

  await tester.pumpWidget(
    DailyPatternApp(dependencies: _testDependencies(database)),
  );
  await tester.pumpAndSettle();

  final context = tester.element(find.byType(DailyPatternApp));
  expect(Theme.of(context).textTheme.bodyMedium?.fontFamily, 'KyoboHandwriting');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
flutter test test\widget_test.dart --plain-name "app uses the bundled Kyobo handwriting font"
```

Expected: FAIL because the app theme has no custom `fontFamily`.

- [ ] **Step 3: Register font in pubspec**

In `pubspec.yaml`, under `flutter:`, add:

```yaml
  fonts:
    - family: KyoboHandwriting
      fonts:
        - asset: assets/KyoboHandwriting2025lyb.ttf
```

- [ ] **Step 4: Apply font in app theme**

In `lib/app/app.dart`, inside `ThemeData(`, add:

```dart
fontFamily: 'KyoboHandwriting',
```

- [ ] **Step 5: Run focused test**

Run:

```powershell
flutter test test\widget_test.dart --plain-name "app uses the bundled Kyobo handwriting font"
```

Expected: PASS.

- [ ] **Step 6: Run verification**

Run:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Expected: all pass.

- [ ] **Step 7: Commit**

Run:

```powershell
git add pubspec.yaml lib\app\app.dart test\widget_test.dart assets\KyoboHandwriting2025lyb.ttf docs\superpowers\plans\2026-04-27-original-vision-gap-plan.md
git commit -m "Apply bundled handwriting font"
```

---

## Phase 1: Real Android Automation Validation

### Task 1: Write The Device Validation Checklist

**Files:**
- Create: `docs/validation/android-device-validation.md`

- [ ] **Step 1: Create the validation document**

Create `docs/validation/android-device-validation.md` with:

```markdown
# Android Device Validation Checklist

## Goal

Verify the app can collect location records, process yesterday's records, and deliver a daily insight notification without developer-only shortcuts.

## Test Device Setup

- Install a debug APK built from the current `master`.
- Enable location permission.
- Enable background location permission if Android settings expose it separately.
- Enable notification permission.
- Disable battery optimization only if the default flow fails; record that result.

## Scenario A: Tracking Starts

1. Open app.
2. Go to `설정`.
3. Turn on `하루 기록`.
4. Confirm Android foreground service notification appears.
5. Return to app.
6. Confirm settings diagnostics show location count increasing after moving.

Expected:
- `하루 기록` switch remains on.
- Foreground notification says the app is recording today's flow.
- Diagnostics eventually show `위치 N개` where `N > 0`.

## Scenario B: Today Records Are Visible

1. Go to `오늘`.
2. Tap `오늘 남긴 기록`.
3. Confirm `오늘 기록중인 위치` appears.

Expected:
- The screen shows `위치 기록 N개`.
- The latest coordinate is shown if records exist.

## Scenario C: Yesterday Processing

1. Use the app for one calendar day, or use debug seed only for development validation.
2. Run `어제 돌아보기 만들기`.
3. Go to `돌아보기`.

Expected:
- Visit count increases if enough stationary points exist.
- At least one reflection appears when the day differs from baseline.
- If no insight appears, settings feedback explains why.

## Scenario D: Daily Notification

1. Set notification time to a near-future minute for validation.
2. Ensure notification permission is granted.
3. Wait for the scheduled time.

Expected:
- A local notification appears.
- Notification title/body use generated reflection copy when a reflection exists.

## Evidence To Capture

- Android version and device model.
- App commit hash.
- Screenshots of settings diagnostics, foreground service notification, today detail, reflection history, and notification shade.
- Any battery optimization setting changes.
```

- [ ] **Step 2: Commit the validation document**

Run:

```powershell
git add docs/validation/android-device-validation.md
git commit -m "Document Android validation checklist"
```

Expected: commit succeeds with only the validation doc staged.

### Task 2: Add A Debug-Only Near-Future Notification Validation Path

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`
- Test: `test/widget_test.dart`

This is not the removed generic "test notification" button. It validates the real daily notification scheduling path by scheduling the existing daily insight notification to the next minute in debug validation tools only.

- [ ] **Step 1: Write failing widget test**

Add this test near the existing debug validation test in `test/widget_test.dart`:

```dart
testWidgets('debug notification validation schedules daily notification soon', (
  tester,
) async {
  final database = AppDatabase(NativeDatabase.memory());
  final notificationAdapter = _FakeNotificationAdapter();
  addTearDown(database.close);

  await tester.pumpWidget(
    DailyPatternApp(
      dependencies: _testDependencies(
        database,
        notificationAdapter: notificationAdapter,
        showDebugValidationTools: true,
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('설정'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('다음 1분에 알림 검증'), 200);
  await tester.tap(find.text('다음 1분에 알림 검증'));
  await tester.pumpAndSettle();

  expect(notificationAdapter.scheduledHour, isNotNull);
  expect(notificationAdapter.scheduledMinute, isNotNull);
  expect(find.text('다음 1분에 돌아보기 알림을 예약했어요'), findsOneWidget);
});
```

Update `_testDependencies` and `_FakeNotificationAdapter` in `test/widget_test.dart`:

```dart
AppDependencies _testDependencies(
  AppDatabase database, {
  SettingsRepository? settingsRepository,
  _FakeTrackingService? trackingService,
  _FakePermissionService? permissionService,
  _FakeNotificationAdapter? notificationAdapter,
  Future<DailyProcessingResult> Function()? runDailyProcessingNow,
  bool showDebugValidationTools = false,
}) {
  final resolvedNotificationAdapter =
      notificationAdapter ?? _FakeNotificationAdapter();
  return AppDependencies(
    database: database,
    settingsRepository: settingsRepository ?? SettingsRepository(),
    trackingService: trackingService ?? _FakeTrackingService(),
    notificationService: NotificationService(resolvedNotificationAdapter),
    permissionService:
        permissionService ?? _FakePermissionService(locationGranted: true),
    maintenanceService: AppMaintenanceService(database),
    importPendingEvents: () async =>
        const LocationEventImportResult(importedCount: 0, skippedCount: 0),
    showDebugValidationTools: showDebugValidationTools,
    runDailyProcessingOverride: runDailyProcessingNow,
  );
}

class _FakeNotificationAdapter implements NotificationAdapter {
  int? scheduledHour;
  int? scheduledMinute;
  String? title;
  String? body;

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
  }) async {
    scheduledHour = hour;
    scheduledMinute = minute;
    this.title = title;
    this.body = body;
  }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
flutter test test\widget_test.dart --plain-name "debug notification validation schedules daily notification soon"
```

Expected: FAIL because `다음 1분에 알림 검증` is not found.

- [ ] **Step 3: Implement debug-only scheduling button**

In `lib/features/settings/settings_screen.dart`, add:

```dart
Future<void> _scheduleDebugNotificationSoon(AppSettings settings) async {
  final now = DateTime.now().add(const Duration(minutes: 1));
  final updated = settings.copyWith(
    notificationEnabled: true,
    notificationHour: now.hour,
    notificationMinute: now.minute,
  );
  await _save(updated);
  await widget.dependencies.notificationService.scheduleDailyInsight(
    hour: updated.notificationHour,
    minute: updated.notificationMinute,
  );
  setState(() {
    _status = '다음 1분에 돌아보기 알림을 예약했어요';
  });
}
```

Inside the existing `if (widget.dependencies.showDebugValidationTools) ...[` block, add:

```dart
const SizedBox(height: 8),
OutlinedButton.icon(
  onPressed: _busy ? null : () => _scheduleDebugNotificationSoon(settings),
  icon: const Icon(Icons.notifications_active_outlined),
  label: const Text('다음 1분에 알림 검증'),
),
```

- [ ] **Step 4: Run focused test**

Run:

```powershell
flutter test test\widget_test.dart --plain-name "debug notification validation schedules daily notification soon"
```

Expected: PASS.

- [ ] **Step 5: Run full verification**

Run:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Expected:
- `flutter analyze`: No issues found.
- `flutter test`: all tests pass.
- `flutter build apk --debug`: debug APK built.

- [ ] **Step 6: Commit**

Run:

```powershell
git add lib\features\settings\settings_screen.dart test\widget_test.dart
git commit -m "Add debug path for notification validation"
```

---

## Phase 2: Map-Based Day Route Visualization

### Task 3: Add Route Models And Repository

**Files:**
- Create: `lib/features/timeline/day_route_models.dart`
- Create: `lib/features/timeline/day_route_repository.dart`
- Create: `test/features/timeline/day_route_repository_test.dart`

- [ ] **Step 1: Write failing repository test**

Create `test/features/timeline/day_route_repository_test.dart`:

```dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/storage/app_database.dart';
import 'package:projectapp_1/features/timeline/day_route_repository.dart';

void main() {
  test('returns ordered route points and visits for a day', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final date = DateTime(2026, 4, 26);
    final placeId = await database
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
    await database.into(database.locationPoints).insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 26, 9, 10),
            latitude: 37.0,
            longitude: 127.0,
            accuracy: 20,
          ),
        );
    await database.into(database.locationPoints).insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 26, 9, 0),
            latitude: 36.9,
            longitude: 126.9,
            accuracy: 20,
          ),
        );
    await database.into(database.visits).insert(
          VisitsCompanion.insert(
            placeClusterId: Value(placeId),
            startedAt: DateTime(2026, 4, 26, 10),
            endedAt: DateTime(2026, 4, 26, 11),
            durationMinutes: 60,
            representativeLatitude: 37.1,
            representativeLongitude: 127.1,
          ),
        );

    final route = await DayRouteRepository(database).loadForDate(date);

    expect(route.points.map((point) => point.timeLabel), ['09:00', '09:10']);
    expect(route.visits.single.placeLabel, '카페');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
flutter test test\features\timeline\day_route_repository_test.dart
```

Expected: FAIL because repository/model files do not exist.

- [ ] **Step 3: Create models**

Create `lib/features/timeline/day_route_models.dart`:

```dart
class DayRouteSnapshot {
  const DayRouteSnapshot({required this.points, required this.visits});

  final List<DayRoutePoint> points;
  final List<DayRouteVisit> visits;
}

class DayRoutePoint {
  const DayRoutePoint({
    required this.timeLabel,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });

  final String timeLabel;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
}

class DayRouteVisit {
  const DayRouteVisit({
    required this.timeLabel,
    required this.placeLabel,
    required this.latitude,
    required this.longitude,
    required this.durationLabel,
  });

  final String timeLabel;
  final String placeLabel;
  final double latitude;
  final double longitude;
  final String durationLabel;
}
```

- [ ] **Step 4: Create repository**

Create `lib/features/timeline/day_route_repository.dart`:

```dart
import '../storage/app_database.dart';
import 'day_route_models.dart';

class DayRouteRepository {
  const DayRouteRepository(this._database);

  final AppDatabase _database;

  Future<DayRouteSnapshot> loadForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final allPoints = await _database.select(_database.locationPoints).get();
    final points = allPoints
        .where(
          (point) =>
              !point.timestamp.isBefore(start) &&
              point.timestamp.isBefore(end) &&
              !point.isMock &&
              point.accuracy <= 200,
        )
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final visits = await (_database.select(_database.visits)
          ..where(
            (visit) =>
                visit.startedAt.isBiggerOrEqualValue(start) &
                visit.startedAt.isSmallerThanValue(end),
          ))
        .get();
    visits.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final places = await _database.select(_database.placeClusters).get();

    return DayRouteSnapshot(
      points: points
          .map(
            (point) => DayRoutePoint(
              timeLabel: _timeLabel(point.timestamp),
              latitude: point.latitude,
              longitude: point.longitude,
              accuracyMeters: point.accuracy,
            ),
          )
          .toList(growable: false),
      visits: visits
          .map((visit) {
            final place = _findPlace(places, visit.placeClusterId);
            return DayRouteVisit(
              timeLabel: _timeLabel(visit.startedAt),
              placeLabel: place?.displayName ?? '이름 없는 장소',
              latitude: visit.representativeLatitude,
              longitude: visit.representativeLongitude,
              durationLabel: _durationLabel(visit.durationMinutes),
            );
          })
          .toList(growable: false),
    );
  }

  PlaceCluster? _findPlace(List<PlaceCluster> places, int? placeClusterId) {
    if (placeClusterId == null) return null;
    for (final place in places) {
      if (place.id == placeClusterId) return place;
    }
    return null;
  }

  String _timeLabel(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _durationLabel(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final rest = minutes % 60;
      if (rest == 0) return '$hours시간 머문 곳';
      return '$hours시간 $rest분 머문 곳';
    }
    return '$minutes분 머문 곳';
  }
}
```

- [ ] **Step 5: Run test**

Run:

```powershell
flutter test test\features\timeline\day_route_repository_test.dart
```

Expected: PASS.

### Task 4: Add A Non-Map Route Preview To Day Detail

**Files:**
- Modify: `lib/features/timeline/day_detail_screen.dart`
- Test: `test/widget_test.dart`

This step adds route visualization without new dependencies. It is a stepping stone before deciding on Google Maps/Mapbox/custom canvas.

- [ ] **Step 1: Write failing widget test**

Add to `test/widget_test.dart`:

```dart
testWidgets('day detail shows route preview from raw points', (tester) async {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  final date = DateTime(2026, 4, 26);
  await database.into(database.locationPoints).insert(
        LocationPointsCompanion.insert(
          timestamp: DateTime(2026, 4, 26, 9),
          latitude: 37,
          longitude: 127,
          accuracy: 20,
        ),
      );
  await database.into(database.locationPoints).insert(
        LocationPointsCompanion.insert(
          timestamp: DateTime(2026, 4, 26, 10),
          latitude: 37.1,
          longitude: 127.1,
          accuracy: 20,
        ),
      );
  await database.into(database.insights).insert(
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
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
flutter test test\widget_test.dart --plain-name "day detail shows route preview from raw points"
```

Expected: FAIL because `이동 경로` is not displayed.

- [ ] **Step 3: Add route repository to `DayDetailScreen`**

In `lib/features/timeline/day_detail_screen.dart`, import:

```dart
import 'day_route_models.dart';
import 'day_route_repository.dart';
```

Extend `_DayDetailSnapshot`:

```dart
final DayRouteSnapshot route;
```

Load it in `_load()`:

```dart
final route = await DayRouteRepository(widget.database).loadForDate(widget.date);
```

Pass it into `_DayDetailSnapshot`.

- [ ] **Step 4: Add route preview card**

Add widget:

```dart
class _RoutePreviewCard extends StatelessWidget {
  const _RoutePreviewCard({required this.route});

  final DayRouteSnapshot route;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(color: AppColors.surfaceAlt),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이동 경로',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '기록 지점 ${route.points.length}개',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            if (route.points.length < 2)
              const Text(
                '경로를 그릴 만큼 위치 기록이 아직 부족해요.',
                style: TextStyle(color: AppColors.muted),
              )
            else
              Text(
                '${route.points.first.timeLabel} → ${route.points.last.timeLabel}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
          ],
        ),
      ),
    );
  }
}
```

Insert before `_SummaryCard`:

```dart
_RoutePreviewCard(route: data.route),
const SizedBox(height: 12),
```

- [ ] **Step 5: Verify**

Run:

```powershell
flutter test test\widget_test.dart --plain-name "day detail shows route preview from raw points"
flutter analyze
flutter test
```

Expected: all pass.

- [ ] **Step 6: Commit**

Run:

```powershell
git add lib\features\timeline\day_route_models.dart lib\features\timeline\day_route_repository.dart lib\features\timeline\day_detail_screen.dart test\features\timeline\day_route_repository_test.dart test\widget_test.dart
git commit -m "Add day route preview data"
```

### Task 5: Decide Real Map Implementation

**Files:**
- Create: `docs/product/map-route-decision.md`

- [ ] **Step 1: Create decision doc**

Create:

```markdown
# Map Route Decision

## Decision Needed

The Notion spec asks for 지도 기반 이동 흐름 표시. Current MVP can show textual route previews without new dependencies. A real map requires choosing a map provider.

## Options

### Option A: No External Map For MVP

Use a custom lightweight canvas/polyline preview from local coordinates.

Pros:
- No API keys.
- No external tracking surface.
- Faster to ship.

Cons:
- Less familiar than real maps.
- Cannot show streets/landmarks.

### Option B: Google Maps

Use Google Maps Flutter plugin.

Pros:
- Familiar map UX.
- Good Android support.

Cons:
- API key, billing, privacy review, dependency setup.

### Option C: OpenStreetMap-Based Flutter Map

Use tile-based map rendering.

Pros:
- More open ecosystem.
- Less tied to Google.

Cons:
- Tile policy, caching, attribution, dependency choices.

## Recommendation

Ship Option A first. Only add a real map after the route preview proves useful on a physical device.
```

- [ ] **Step 2: Commit**

Run:

```powershell
git add docs/product/map-route-decision.md
git commit -m "Record map route implementation decision"
```

---

## Phase 3: Pattern Analysis Beyond Simple Deltas

### Task 6: Add Pattern Analysis Models And Service

**Files:**
- Create: `lib/features/insights/pattern_analysis_models.dart`
- Create: `lib/features/insights/pattern_analysis_service.dart`
- Create: `test/features/insights/pattern_analysis_service_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/features/insights/pattern_analysis_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/analysis/daily_summary_service.dart';
import 'package:projectapp_1/features/insights/pattern_analysis_service.dart';

void main() {
  test('detects decreasing movement trend across recent days', () {
    final service = PatternAnalysisService();
    final days = [
      _summary('2026-04-20', 5000, 60, 3),
      _summary('2026-04-21', 4200, 52, 3),
      _summary('2026-04-22', 3400, 43, 2),
      _summary('2026-04-23', 2600, 35, 2),
      _summary('2026-04-24', 1800, 24, 1),
    ];

    final signals = service.analyze(days);

    expect(signals.map((signal) => signal.type), contains(PatternSignalType.decreasingMovement));
  });

  test('does not emit trend signal when there are fewer than four summaries', () {
    final service = PatternAnalysisService();
    final signals = service.analyze([
      _summary('2026-04-22', 3000, 30, 2),
      _summary('2026-04-23', 2500, 25, 2),
      _summary('2026-04-24', 2000, 20, 2),
    ]);

    expect(signals, isEmpty);
  });
}

DailySummarySnapshot _summary(
  String date,
  double distance,
  int movingMinutes,
  int visitCount,
) {
  return DailySummarySnapshot(
    date: DateTime.parse(date),
    totalDistanceMeters: distance,
    movingMinutes: movingMinutes,
    stationaryMinutes: 120,
    visitCount: visitCount,
    newPlaceCount: 0,
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
flutter test test\features\insights\pattern_analysis_service_test.dart
```

Expected: FAIL because files do not exist.

- [ ] **Step 3: Create models**

Create `lib/features/insights/pattern_analysis_models.dart`:

```dart
enum PatternSignalType {
  decreasingMovement,
  increasingMovement,
  decreasingVisits,
  increasingVisits,
}

class PatternSignal {
  const PatternSignal({
    required this.type,
    required this.strength,
    required this.evidence,
  });

  final PatternSignalType type;
  final double strength;
  final String evidence;
}
```

- [ ] **Step 4: Create service**

Create `lib/features/insights/pattern_analysis_service.dart`:

```dart
import '../analysis/daily_summary_service.dart';
import 'pattern_analysis_models.dart';

export 'pattern_analysis_models.dart';

class PatternAnalysisService {
  const PatternAnalysisService();

  List<PatternSignal> analyze(List<DailySummarySnapshot> summaries) {
    if (summaries.length < 4) return const [];
    final ordered = [...summaries]..sort((a, b) => a.date.compareTo(b.date));
    final signals = <PatternSignal>[];

    final firstDistance = ordered.first.totalDistanceMeters;
    final lastDistance = ordered.last.totalDistanceMeters;
    if (firstDistance > 0 && lastDistance < firstDistance * 0.6) {
      signals.add(
        PatternSignal(
          type: PatternSignalType.decreasingMovement,
          strength: 1 - (lastDistance / firstDistance),
          evidence:
              '${firstDistance.round()}m에서 ${lastDistance.round()}m로 줄었어요',
        ),
      );
    }
    if (firstDistance > 0 && lastDistance > firstDistance * 1.4) {
      signals.add(
        PatternSignal(
          type: PatternSignalType.increasingMovement,
          strength: (lastDistance / firstDistance) - 1,
          evidence:
              '${firstDistance.round()}m에서 ${lastDistance.round()}m로 늘었어요',
        ),
      );
    }

    final firstVisits = ordered.first.visitCount;
    final lastVisits = ordered.last.visitCount;
    if (firstVisits > 0 && lastVisits < firstVisits) {
      signals.add(
        PatternSignal(
          type: PatternSignalType.decreasingVisits,
          strength: (firstVisits - lastVisits) / firstVisits,
          evidence: '$firstVisits곳에서 $lastVisits곳으로 줄었어요',
        ),
      );
    }
    if (firstVisits > 0 && lastVisits > firstVisits) {
      signals.add(
        PatternSignal(
          type: PatternSignalType.increasingVisits,
          strength: (lastVisits - firstVisits) / firstVisits,
          evidence: '$firstVisits곳에서 $lastVisits곳으로 늘었어요',
        ),
      );
    }

    signals.sort((a, b) => b.strength.compareTo(a.strength));
    return signals.take(2).toList(growable: false);
  }
}
```

- [ ] **Step 5: Run test**

Run:

```powershell
flutter test test\features\insights\pattern_analysis_service_test.dart
```

Expected: PASS.

### Task 7: Integrate Pattern Signals Into Insight Generation

**Files:**
- Modify: `lib/features/background/daily_insight_worker.dart`
- Modify: `lib/features/insights/insight_generation_service.dart`
- Modify: `lib/features/insights/insight_models.dart`
- Modify: `lib/features/insights/insight_narrator.dart`
- Test: `test/features/background/daily_insight_worker_test.dart`
- Test: `test/features/insights/insight_generation_service_test.dart`

- [ ] **Step 1: Write failing insight generation test**

Add to `test/features/insights/insight_generation_service_test.dart`:

```dart
test('generates decreasing movement trend insight from pattern signal', () {
  final service = InsightGenerationService();

  final insights = service.generate(
    yesterday: _summary(distance: 1000, movingMinutes: 15, visitCount: 1),
    recentAverage: const DailySummaryBaseline(
      totalDistanceMeters: 3000,
      movingMinutes: 30,
      visitCount: 2,
    ),
    patternSignals: const [
      PatternSignal(
        type: PatternSignalType.decreasingMovement,
        strength: 0.7,
        evidence: '최근 이동이 계속 줄었어요',
      ),
    ],
  );

  expect(insights.first.type, InsightType.routineTrend);
  expect(insights.first.title, contains('최근'));
});
```

If helper `_summary` does not exist in that file, add:

```dart
DailySummarySnapshot _summary({
  required double distance,
  required int movingMinutes,
  required int visitCount,
}) {
  return DailySummarySnapshot(
    date: DateTime(2026, 4, 26),
    totalDistanceMeters: distance,
    movingMinutes: movingMinutes,
    stationaryMinutes: 60,
    visitCount: visitCount,
    newPlaceCount: 0,
  );
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
flutter test test\features\insights\insight_generation_service_test.dart --plain-name "generates decreasing movement trend insight from pattern signal"
```

Expected: FAIL because `patternSignals` and `routineTrend` do not exist.

- [ ] **Step 3: Extend models**

In `lib/features/insights/insight_models.dart`, add to `InsightType`:

```dart
routineTrend,
```

- [ ] **Step 4: Extend generation API**

In `lib/features/insights/insight_generation_service.dart`, import pattern models:

```dart
import 'pattern_analysis_models.dart';
```

Change `generate` signature:

```dart
List<GeneratedInsight> generate({
  required DailySummarySnapshot yesterday,
  required DailySummaryBaseline recentAverage,
  List<PatternSignal> patternSignals = const [],
})
```

Before sorting, add:

```dart
for (final signal in patternSignals) {
  insights.add(_patternInsight(signal));
}
```

Add:

```dart
GeneratedInsight _patternInsight(PatternSignal signal) {
  final text = _narrator.narratePattern(signal);
  return GeneratedInsight(
    type: InsightType.routineTrend,
    severity: InsightSeverity.important,
    title: text.title,
    body: text.body,
    evidence: signal.evidence,
  );
}
```

Update `_typeRank`:

```dart
InsightType.routineTrend => 6,
```

- [ ] **Step 5: Extend narrator**

In `lib/features/insights/insight_narrator.dart`, add import:

```dart
import 'pattern_analysis_models.dart';
```

Add method to `InsightNarrator`:

```dart
InsightNarrationText narratePattern(PatternSignal signal);
```

Implement in `RuleBasedInsightNarrator`:

```dart
@override
InsightNarrationText narratePattern(PatternSignal signal) {
  return switch (signal.type) {
    PatternSignalType.decreasingMovement => InsightNarrationText(
        title: '최근 이동이 줄어드는 흐름이에요',
        body: '며칠 사이 움직임이 조금씩 줄어든 패턴이 보여요.',
        evidence: signal.evidence,
      ),
    PatternSignalType.increasingMovement => InsightNarrationText(
        title: '최근 이동이 늘어나는 흐름이에요',
        body: '며칠 사이 움직임이 조금씩 늘어난 패턴이 보여요.',
        evidence: signal.evidence,
      ),
    PatternSignalType.decreasingVisits => InsightNarrationText(
        title: '최근 들른 곳이 줄고 있어요',
        body: '방문 장소 수가 이전보다 적어지는 흐름이 보여요.',
        evidence: signal.evidence,
      ),
    PatternSignalType.increasingVisits => InsightNarrationText(
        title: '최근 들른 곳이 늘고 있어요',
        body: '방문 장소 수가 이전보다 많아지는 흐름이 보여요.',
        evidence: signal.evidence,
      ),
  };
}
```

- [ ] **Step 6: Integrate into worker**

In `lib/features/background/daily_insight_worker.dart`, import:

```dart
import '../insights/pattern_analysis_service.dart';
```

Add constructor dependency:

```dart
PatternAnalysisService? patternAnalysisService,
```

Add field:

```dart
final PatternAnalysisService _patternAnalysisService;
```

Initialize:

```dart
_patternAnalysisService = patternAnalysisService ?? const PatternAnalysisService(),
```

After `summary` creation and before `generate`, load recent summaries:

```dart
final recentSummaries = await _recentSummaries(through: yesterday);
final patternSignals = _patternAnalysisService.analyze([
  ...recentSummaries,
  summary,
]);
```

Call:

```dart
final insights = _insightGenerationService.generate(
  yesterday: summary,
  recentAverage: recentAverage,
  patternSignals: patternSignals,
);
```

Add helper:

```dart
Future<List<DailySummarySnapshot>> _recentSummaries({
  required DateTime through,
}) async {
  final rows = await _database.select(_database.dailySummaries).get();
  final start = through.subtract(const Duration(days: 7));
  return rows
      .where((row) {
        final date = DateTime.parse(row.date);
        return !date.isBefore(start) && date.isBefore(through);
      })
      .map(
        (row) => DailySummarySnapshot(
          date: DateTime.parse(row.date),
          totalDistanceMeters: row.totalDistanceMeters,
          movingMinutes: row.movingMinutes,
          stationaryMinutes: row.stationaryMinutes,
          visitCount: row.visitCount,
          newPlaceCount: row.newPlaceCount,
          longestStayPlaceId: row.longestStayPlaceId,
        ),
      )
      .toList(growable: false);
}
```

- [ ] **Step 7: Verify**

Run:

```powershell
flutter test test\features\insights\insight_generation_service_test.dart
flutter test test\features\background\daily_insight_worker_test.dart
flutter analyze
flutter test
```

Expected: all pass.

- [ ] **Step 8: Commit**

Run:

```powershell
git add lib\features\insights lib\features\background\daily_insight_worker.dart test\features\insights test\features\background\daily_insight_worker_test.dart
git commit -m "Add trend-based insight signals"
```

---

## Phase 4: AI-Ready Narrative Boundary

### Task 8: Add An Optional AI Narrator Interface Without Network Calls

**Files:**
- Modify: `lib/features/insights/insight_narrator.dart`
- Create: `test/features/insights/insight_narrator_test.dart`

This prepares the boundary but does not add an OpenAI dependency. No new dependency is allowed until the product decision is explicit.

- [ ] **Step 1: Write test for narrator contract**

Create `test/features/insights/insight_narrator_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/insights/insight_models.dart';
import 'package:projectapp_1/features/insights/insight_narrator.dart';

void main() {
  test('rule based narrator produces Korean movement copy', () {
    const narrator = RuleBasedInsightNarrator();

    final text = narrator.narrate(
      const InsightNarrationContext(
        type: InsightType.movementChange,
        severity: InsightSeverity.notable,
        direction: InsightDirection.lower,
        currentValue: 1000,
        baselineValue: 3000,
      ),
    );

    expect(text.title, contains('조용한'));
    expect(text.body, isNotEmpty);
    expect(text.evidence, isNotEmpty);
  });
}
```

- [ ] **Step 2: Run test**

Run:

```powershell
flutter test test\features\insights\insight_narrator_test.dart
```

Expected: PASS if current narrator already satisfies this. If it fails only due wording, update expected phrase to current approved Korean wording.

- [ ] **Step 3: Document AI boundary**

At the top of `lib/features/insights/insight_narrator.dart`, add:

```dart
/// Converts validated analytic signals into user-facing Korean copy.
///
/// This layer is intentionally separated from InsightGenerationService so a
/// future AI-backed implementation can rewrite expression without changing
/// analysis rules, persistence, or notification scheduling.
```

- [ ] **Step 4: Commit**

Run:

```powershell
git add lib\features\insights\insight_narrator.dart test\features\insights\insight_narrator_test.dart
git commit -m "Document insight narrator boundary"
```

---

## Phase 5: Product Finish And Trust

### Task 9: Replace Remaining Placeholder App Identity

**Files:**
- Modify: `lib/app/app.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `pubspec.yaml`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write failing shell title test**

Add to `test/widget_test.dart`:

```dart
testWidgets('app shell does not expose placeholder project name', (tester) async {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);

  await tester.pumpWidget(
    DailyPatternApp(dependencies: _testDependencies(database)),
  );
  await tester.pumpAndSettle();

  expect(find.text('projectapp_1'), findsNothing);
  expect(find.text('오늘'), findsWidgets);
});
```

- [ ] **Step 2: Run test**

Run:

```powershell
flutter test test\widget_test.dart --plain-name "app shell does not expose placeholder project name"
```

Expected: PASS if placeholder is already hidden from UI. If FAIL, replace visible placeholder copy with blank or approved name.

- [ ] **Step 3: Decide app display name**

If app name is still undecided, use neutral temporary display name:

```text
하루 기록
```

Do not invent a final brand name without product approval.

- [ ] **Step 4: Commit**

Run:

```powershell
git add lib\app\app.dart android\app\src\main\AndroidManifest.xml pubspec.yaml test\widget_test.dart
git commit -m "Remove placeholder app identity"
```

### Task 10: Add Privacy And Battery Trust Section In Settings

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write failing widget test**

Add:

```dart
testWidgets('settings explains local privacy and battery behavior', (tester) async {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);

  await tester.pumpWidget(
    DailyPatternApp(dependencies: _testDependencies(database)),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('설정'));
  await tester.pumpAndSettle();

  expect(find.text('기록은 이 기기에만 저장돼요'), findsOneWidget);
  expect(find.text('움직임이 있을 때 중심으로 남겨 배터리 사용을 줄여요'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
flutter test test\widget_test.dart --plain-name "settings explains local privacy and battery behavior"
```

Expected: FAIL because trust copy is not present.

- [ ] **Step 3: Add trust card**

In `lib/features/settings/settings_screen.dart`, add a card near the top of the scrollable list:

```dart
const _TrustCard(),
const SizedBox(height: 8),
```

Add widget:

```dart
class _TrustCard extends StatelessWidget {
  const _TrustCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(color: AppColors.surfaceAlt),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기록은 이 기기에만 저장돼요',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6),
            Text(
              '움직임이 있을 때 중심으로 남겨 배터리 사용을 줄여요',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Verify and commit**

Run:

```powershell
flutter test test\widget_test.dart --plain-name "settings explains local privacy and battery behavior"
flutter analyze
flutter test
git add lib\features\settings\settings_screen.dart test\widget_test.dart
git commit -m "Explain privacy and battery behavior"
```

---

## Recommended Execution Order

1. Task 1: Android validation checklist.
2. Task 2: Debug-only real notification scheduling validation.
3. Task 3: Route data repository.
4. Task 4: Route preview in day detail.
5. Task 5: Map implementation decision.
6. Task 6: Pattern analysis service.
7. Task 7: Trend insights integration.
8. Task 8: AI-ready narrator boundary documentation.
9. Task 10: Privacy/battery trust section.
10. Task 9: App identity after the user approves a temporary or final name.

---

## Self-Review

Spec coverage:
- Automatic collection: covered by Phase 1 validation.
- Data processing into meaningful places and day flow: covered by current code plus Phase 2 route data.
- Pattern analysis and change detection: covered by Phase 3.
- AI-natural phrasing boundary: covered by Phase 4.
- User delivery via 9 AM notification: covered by Phase 1 Task 2 validation path.
- Map visualization: covered by Phase 2 and Task 5 decision.
- Privacy and battery concerns: covered by Phase 5 Task 10.

Known gaps intentionally not implemented in this plan:
- Real AI API integration. This needs a separate product/security decision and API key handling plan.
- Real map SDK dependency. This needs Task 5 decision first.
- Health, app usage, spending data. These are Notion expansion ideas, not MVP blockers.
- Personalized behavior recommendations. This should follow after insight quality is validated.

Placeholder scan:
- No `TBD` or `TODO` placeholders remain.
- Tasks include exact files, exact tests, commands, and expected outcomes.

Type consistency:
- New `DayRouteSnapshot`, `PatternSignal`, and `PatternSignalType` are defined before later tasks reference them.
- Notification validation reuses `scheduleDailyInsight`; no removed `showTestNotification` path is reintroduced.
