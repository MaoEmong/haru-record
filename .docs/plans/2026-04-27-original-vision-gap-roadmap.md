# Original Vision Gap Roadmap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the gap between the current MVP and the original product promise: automatically record a day, organize movement into meaningful places, analyze patterns, and deliver a daily reflection.

**Architecture:** Keep the app local-first and Android-first. Build in thin vertical slices: first make the existing data pipeline truthful, then surface the day as a timeline, then improve reflections and notification delivery. Defer full map-route visualization until place/timeline data is reliable.

**Tech Stack:** Flutter Material 3, Dart, Drift/SQLite, Android Kotlin foreground service, Workmanager, flutter_local_notifications, existing Blue Ink UI theme.

---

## Current Gap Summary

The app already has the core skeleton:

- Android foreground location event recording.
- Local SQLite storage for raw points, visits, daily summaries, places, and reflections.
- Rule-based daily reflection generation.
- Manual daily processing.
- Local notification scheduling.
- Today, Reflections, Frequent Places, and Settings tabs.
- Korean emotional copy and Blue Ink styling.

The largest gaps against the original image are:

- Visits are generated, but place clusters are not yet reliably created/linked during daily processing.
- There is no day timeline showing `09:00 집 -> 09:30 회사 -> 12:30 카페`.
- There is no map or route visualization.
- Reflections are rule-based and shallow; no AI narrator boundary is active.
- Morning notification is scheduled, but it does not carry the strongest reflection content or deep-link into the relevant screen.
- Real-device validation remains incomplete.
- Privacy and battery value props exist in settings/data deletion, but not as polished product surfaces.

## File Structure

- Modify `lib/features/background/daily_insight_worker.dart`: return richer processing results, create/link place clusters, persist daily visits with place IDs.
- Create `lib/features/places/place_cluster_repository.dart`: owns place-cluster matching, creation, updating, and visit-count increments.
- Create `test/features/places/place_cluster_repository_test.dart`: validates cluster matching and count updates.
- Modify `lib/features/analysis/daily_summary_service.dart`: include timeline-ready metrics from visits.
- Create `lib/features/timeline/day_timeline_models.dart`: UI-facing timeline item model.
- Create `lib/features/timeline/day_timeline_repository.dart`: reads visits + place clusters and returns ordered timeline items.
- Create `test/features/timeline/day_timeline_repository_test.dart`: validates timeline ordering and fallback place labels.
- Modify `lib/features/home/home_screen.dart`: add a compact today/timeline preview below today record summary.
- Modify `lib/features/history/history_screen.dart`: show date-grouped reflection cards with summary evidence.
- Modify `lib/features/places/place_management_screen.dart`: show last visited date and actual visit count from linked visits.
- Modify `lib/features/insights/insight_generation_service.dart`: split structured candidate generation from wording.
- Create `lib/features/insights/insight_narrator.dart`: local deterministic narrator boundary for future AI wording.
- Modify `lib/features/notifications/notification_service.dart`: allow scheduling title/body from generated reflection text.
- Modify `lib/main.dart` and app shell files only if notification tap routing requires navigator state.
- Modify `test/widget_test.dart`: cover timeline preview, empty examples, notification/processing messages.
- Update `.docs/status/2026-04-27-android-device-validation.md`: record physical-device validation results.

---

### Task 1: Make Place Clusters Real In Daily Processing

**Files:**
- Create: `lib/features/places/place_cluster_repository.dart`
- Create: `test/features/places/place_cluster_repository_test.dart`
- Modify: `lib/features/background/daily_insight_worker.dart`
- Test: `test/features/background/daily_insight_worker_test.dart`

- [ ] **Step 1: Write the repository tests**

Add `test/features/places/place_cluster_repository_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/places/place_cluster_repository.dart';
import 'package:projectapp_1/features/storage/app_database.dart';

void main() {
  test('creates a new place cluster when no nearby cluster exists', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = PlaceClusterRepository(database);

    final cluster = await repository.findOrCreateForVisit(
      latitude: 37.5665,
      longitude: 126.9780,
      radiusMeters: 100,
      visitedAt: DateTime(2026, 4, 26, 9),
    );

    expect(cluster.id, isPositive);
    expect(cluster.visitCount, 1);
    expect(cluster.displayName, isNull);
  });

  test('reuses a nearby place cluster and increments visit count', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = PlaceClusterRepository(database);

    final first = await repository.findOrCreateForVisit(
      latitude: 37.5665,
      longitude: 126.9780,
      radiusMeters: 100,
      visitedAt: DateTime(2026, 4, 26, 9),
    );
    final second = await repository.findOrCreateForVisit(
      latitude: 37.5666,
      longitude: 126.9781,
      radiusMeters: 100,
      visitedAt: DateTime(2026, 4, 27, 9),
    );

    expect(second.id, first.id);
    expect(second.visitCount, 2);
  });
}
```

- [ ] **Step 2: Run tests to verify RED**

Run:

```powershell
flutter test test\features\places\place_cluster_repository_test.dart
```

Expected: compile failure because `PlaceClusterRepository` does not exist.

- [ ] **Step 3: Implement the repository**

Create `lib/features/places/place_cluster_repository.dart`:

```dart
import 'package:drift/drift.dart' show Value;

import '../../core/geo/geo_math.dart';
import '../storage/app_database.dart';

class PlaceClusterRepository {
  const PlaceClusterRepository(this._database);

  final AppDatabase _database;

  Future<PlaceCluster> findOrCreateForVisit({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required DateTime visitedAt,
  }) async {
    final clusters = await _database.select(_database.placeClusters).get();
    for (final cluster in clusters) {
      final distance = distanceMeters(
        cluster.centerLatitude,
        cluster.centerLongitude,
        latitude,
        longitude,
      );
      if (distance <= radiusMeters) {
        final updated = PlaceClustersCompanion(
          centerLatitude: Value(
            (cluster.centerLatitude * cluster.visitCount + latitude) /
                (cluster.visitCount + 1),
          ),
          centerLongitude: Value(
            (cluster.centerLongitude * cluster.visitCount + longitude) /
                (cluster.visitCount + 1),
          ),
          updatedAt: Value(visitedAt),
          visitCount: Value(cluster.visitCount + 1),
        );
        await (_database.update(_database.placeClusters)
              ..where((row) => row.id.equals(cluster.id)))
            .write(updated);
        final rows = await (_database.select(_database.placeClusters)
              ..where((row) => row.id.equals(cluster.id)))
            .get();
        return rows.single;
      }
    }

    final id = await _database.into(_database.placeClusters).insert(
          PlaceClustersCompanion.insert(
            centerLatitude: latitude,
            centerLongitude: longitude,
            radiusMeters: radiusMeters,
            createdAt: visitedAt,
            updatedAt: visitedAt,
            visitCount: 1,
          ),
        );
    final rows = await (_database.select(_database.placeClusters)
          ..where((row) => row.id.equals(id)))
        .get();
    return rows.single;
  }
}
```

- [ ] **Step 4: Link visits to clusters in daily processing**

Modify `lib/features/background/daily_insight_worker.dart`:

```dart
import '../places/place_cluster_repository.dart';
```

Add a constructor dependency:

```dart
PlaceClusterRepository? placeClusterRepository,
```

Store it:

```dart
_placeClusterRepository =
    placeClusterRepository ?? PlaceClusterRepository(database),
```

Add the field:

```dart
final PlaceClusterRepository _placeClusterRepository;
```

Before `_replaceDailyOutputs`, map detected visits to place cluster IDs:

```dart
final persistedVisits = <_PersistableVisit>[];
var newPlaceCount = 0;
for (final visit in visits) {
  final before = await _database.select(_database.placeClusters).get();
  final cluster = await _placeClusterRepository.findOrCreateForVisit(
    latitude: visit.latitude,
    longitude: visit.longitude,
    radiusMeters: _settings.minimumMovementMeters.toDouble(),
    visitedAt: visit.startedAt,
  );
  final existed = before.any((existing) => existing.id == cluster.id);
  if (!existed) newPlaceCount++;
  persistedVisits.add(_PersistableVisit(visit: visit, placeClusterId: cluster.id));
}
```

Add a private helper class near the processor:

```dart
class _PersistableVisit {
  const _PersistableVisit({required this.visit, required this.placeClusterId});

  final DetectedVisit visit;
  final int placeClusterId;
}
```

Update `_replaceDailyOutputs` to accept `List<_PersistableVisit>` and insert `placeClusterId: Value(item.placeClusterId)`.

- [ ] **Step 5: Update summary new-place count**

After building `summary`, replace only the `newPlaceCount` value by creating a new snapshot:

```dart
final summary = DailySummarySnapshot(
  date: rawSummary.date,
  totalDistanceMeters: rawSummary.totalDistanceMeters,
  movingMinutes: rawSummary.movingMinutes,
  stationaryMinutes: rawSummary.stationaryMinutes,
  visitCount: rawSummary.visitCount,
  newPlaceCount: newPlaceCount,
  longestStayPlaceId: rawSummary.longestStayPlaceId,
);
```

- [ ] **Step 6: Run focused tests**

Run:

```powershell
flutter test test\features\places\place_cluster_repository_test.dart test\features\background\daily_insight_worker_test.dart
```

Expected: all tests pass.

- [ ] **Step 7: Commit**

```powershell
git add lib\features\places\place_cluster_repository.dart lib\features\background\daily_insight_worker.dart test\features\places\place_cluster_repository_test.dart test\features\background\daily_insight_worker_test.dart
git commit -m "Connect visits to persistent places"
```

---

### Task 2: Add A Day Timeline Repository

**Files:**
- Create: `lib/features/timeline/day_timeline_models.dart`
- Create: `lib/features/timeline/day_timeline_repository.dart`
- Create: `test/features/timeline/day_timeline_repository_test.dart`

- [ ] **Step 1: Write the timeline repository test**

Create `test/features/timeline/day_timeline_repository_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/storage/app_database.dart';
import 'package:projectapp_1/features/timeline/day_timeline_repository.dart';

void main() {
  test('returns visits ordered by start time with place labels', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final placeId = await database.into(database.placeClusters).insert(
          PlaceClustersCompanion.insert(
            centerLatitude: 37,
            centerLongitude: 127,
            radiusMeters: 100,
            displayName: const Value('집 근처'),
            createdAt: DateTime(2026, 4, 26),
            updatedAt: DateTime(2026, 4, 26),
            visitCount: 1,
          ),
        );
    await database.into(database.visits).insert(
          VisitsCompanion.insert(
            placeClusterId: Value(placeId),
            startedAt: DateTime(2026, 4, 26, 9),
            endedAt: DateTime(2026, 4, 26, 10),
            durationMinutes: 60,
            representativeLatitude: 37,
            representativeLongitude: 127,
          ),
        );

    final repository = DayTimelineRepository(database);
    final items = await repository.loadForDate(DateTime(2026, 4, 26));

    expect(items, hasLength(1));
    expect(items.single.placeLabel, '집 근처');
    expect(items.single.timeLabel, '09:00');
    expect(items.single.durationLabel, '1시간 머문 곳');
  });
}
```

- [ ] **Step 2: Run test to verify RED**

```powershell
flutter test test\features\timeline\day_timeline_repository_test.dart
```

Expected: compile failure because timeline repository files do not exist.

- [ ] **Step 3: Create timeline model**

Create `lib/features/timeline/day_timeline_models.dart`:

```dart
class DayTimelineItem {
  const DayTimelineItem({
    required this.timeLabel,
    required this.placeLabel,
    required this.durationLabel,
  });

  final String timeLabel;
  final String placeLabel;
  final String durationLabel;
}
```

- [ ] **Step 4: Create timeline repository**

Create `lib/features/timeline/day_timeline_repository.dart`:

```dart
import '../storage/app_database.dart';
import 'day_timeline_models.dart';

class DayTimelineRepository {
  const DayTimelineRepository(this._database);

  final AppDatabase _database;

  Future<List<DayTimelineItem>> loadForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final visits = await _database.select(_database.visits).get()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final places = await _database.select(_database.placeClusters).get();
    return visits
        .where((visit) =>
            !visit.startedAt.isBefore(start) && visit.startedAt.isBefore(end))
        .map((visit) {
      final place = places
          .where((place) => place.id == visit.placeClusterId)
          .firstOrNull;
      return DayTimelineItem(
        timeLabel: _timeLabel(visit.startedAt),
        placeLabel: place?.displayName ?? '이름을 정하지 않은 곳',
        durationLabel: _durationLabel(visit.durationMinutes),
      );
    }).toList(growable: false);
  }

  String _timeLabel(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _durationLabel(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final rest = minutes % 60;
      if (rest == 0) return '$hours시간 머문 곳';
      return '$hours시간 ${rest}분 머문 곳';
    }
    return '$minutes분 머문 곳';
  }
}
```

- [ ] **Step 5: Run focused test**

```powershell
flutter test test\features\timeline\day_timeline_repository_test.dart
```

Expected: pass.

- [ ] **Step 6: Commit**

```powershell
git add lib\features\timeline test\features\timeline
git commit -m "Add daily timeline data model"
```

---

### Task 3: Show Timeline Preview On Today

**Files:**
- Modify: `lib/features/home/home_screen.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Add widget test**

Add a test to `test/widget_test.dart`:

```dart
testWidgets('home shows a compact timeline preview when visits exist', (tester) async {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  final placeId = await database.into(database.placeClusters).insert(
        PlaceClustersCompanion.insert(
          centerLatitude: 37,
          centerLongitude: 127,
          radiusMeters: 100,
          displayName: const Value('집 근처'),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          visitCount: 1,
        ),
      );
  await database.into(database.visits).insert(
        VisitsCompanion.insert(
          placeClusterId: Value(placeId),
          startedAt: DateTime.now(),
          endedAt: DateTime.now().add(const Duration(minutes: 70)),
          durationMinutes: 70,
          representativeLatitude: 37,
          representativeLongitude: 127,
        ),
      );

  await tester.pumpWidget(DailyPatternApp(dependencies: _testDependencies(database)));
  await tester.pumpAndSettle();

  expect(find.text('오늘의 흐름'), findsOneWidget);
  expect(find.text('집 근처'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify RED**

```powershell
flutter test test\widget_test.dart --plain-name "home shows a compact timeline preview when visits exist"
```

Expected: fail because Home does not render timeline preview.

- [ ] **Step 3: Load timeline preview in Home**

Modify `lib/features/home/home_screen.dart`:

```dart
import '../timeline/day_timeline_models.dart';
import '../timeline/day_timeline_repository.dart';
```

In `_load`, load today timeline:

```dart
final timeline = await DayTimelineRepository(
  widget.dependencies.database,
).loadForDate(DateTime.now());
```

Add `timeline: timeline.take(3).toList(growable: false)` to `_HomeSnapshot`.

- [ ] **Step 4: Render timeline card**

Add after `_TodayRecordPanel`:

```dart
if (data.timeline.isNotEmpty) ...[
  const SizedBox(height: 12),
  _TimelinePreview(items: data.timeline),
],
```

Implement `_TimelinePreview`:

```dart
class _TimelinePreview extends StatelessWidget {
  const _TimelinePreview({required this.items});

  final List<DayTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('오늘의 흐름', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (final item in items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(item.placeLabel),
                subtitle: Text('${item.timeLabel} · ${item.durationLabel}'),
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run widget test**

```powershell
flutter test test\widget_test.dart
```

Expected: pass.

- [ ] **Step 6: Commit**

```powershell
git add lib\features\home\home_screen.dart test\widget_test.dart
git commit -m "Show daily timeline preview on Today"
```

---

### Task 4: Improve Reflections With A Narrator Boundary

**Files:**
- Create: `lib/features/insights/insight_narrator.dart`
- Modify: `lib/features/insights/insight_generation_service.dart`
- Modify: `test/features/insights/insight_generation_service_test.dart`

Implementation note: completed with `InsightNarrationContext`,
`InsightText`, `InsightNarrator`, and `RuleBasedInsightNarrator`.
`InsightGenerationService` now detects insight candidates and delegates
wording to the narrator boundary.

- [x] **Step 1: Add narrator test**

Add to `test/features/insights/insight_generation_service_test.dart`:

```dart
test('uses narrator wording for movement reflections', () {
  final service = InsightGenerationService(narrator: RuleBasedInsightNarrator());

  final insights = service.generate(
    yesterday: DailySummarySnapshot(
      date: DateTime(2026, 4, 25),
      totalDistanceMeters: 500,
      movingMinutes: 10,
      stationaryMinutes: 700,
      visitCount: 1,
      newPlaceCount: 0,
    ),
    recentAverage: DailySummaryBaseline(
      totalDistanceMeters: 2000,
      movingMinutes: 45,
      visitCount: 3,
    ),
  );

  expect(insights.first.title, '어제는 조금 조용한 하루였어요');
});
```

- [x] **Step 2: Run test to verify RED**

```powershell
flutter test test\features\insights\insight_generation_service_test.dart
```

Expected: compile failure because narrator constructor/boundary does not exist.

- [x] **Step 3: Create narrator boundary**

Create `lib/features/insights/insight_narrator.dart`:

```dart
import 'insight_models.dart';

class InsightText {
  const InsightText({
    required this.title,
    required this.body,
    required this.evidence,
  });

  final String title;
  final String body;
  final String evidence;
}

abstract interface class InsightNarrator {
  InsightText narrate({
    required InsightType type,
    required bool isHigher,
    required num current,
    required num baseline,
  });
}

class RuleBasedInsightNarrator implements InsightNarrator {
  @override
  InsightText narrate({
    required InsightType type,
    required bool isHigher,
    required num current,
    required num baseline,
  }) {
    if (type == InsightType.movementChange) {
      return InsightText(
        title: isHigher ? '어제는 평소보다 많이 움직였어요' : '어제는 조금 조용한 하루였어요',
        body: isHigher ? '최근 며칠보다 이동이 많은 하루였어요.' : '최근 며칠보다 이동이 적고 차분했어요.',
        evidence: '${current.round()}m, 최근 평균 ${baseline.round()}m',
      );
    }
    return const InsightText(
      title: '하루 흐름이 조금 달랐어요',
      body: '최근 며칠과 다른 움직임이 있었어요.',
      evidence: '최근 평균과 비교',
    );
  }
}
```

- [x] **Step 4: Inject narrator into service**

Modify `InsightGenerationService`:

```dart
InsightGenerationService({InsightNarrator? narrator})
    : _narrator = narrator ?? RuleBasedInsightNarrator();

final InsightNarrator _narrator;
```

Use `_narrator.narrate(...)` when creating movement insights.

- [x] **Step 5: Run insight tests**

```powershell
flutter test test\features\insights\insight_generation_service_test.dart
```

Expected: pass.

- [x] **Step 6: Commit**

```powershell
git add lib\features\insights test\features\insights
git commit -m "Add narrator boundary for reflections"
```

---

### Task 5: Put Strongest Reflection Into Daily Notification

**Files:**
- Modify: `lib/features/background/daily_insight_worker.dart`
- Modify: `lib/features/notifications/notification_service.dart`
- Modify: `test/features/background/daily_insight_worker_test.dart`
- Modify: `test/features/notifications/notification_service_test.dart`

Implementation note: completed with optional `title`/`body` parameters on
`scheduleDailyInsight` instead of a separate `scheduleDailyReflection` method,
so existing settings flows keep the fallback copy while daily processing can
pass the strongest generated reflection directly.

- [x] **Step 1: Update notification adapter test**

Modify `FakeNotificationAdapter` in `test/features/background/daily_insight_worker_test.dart` to capture `title` and `body`.

Add expectations:

```dart
expect(notificationAdapter.scheduledTitle, '어제 하루를 정리했어요');
expect(notificationAdapter.scheduledBody, contains('조금 조용한 하루'));
```

- [x] **Step 2: Run test to verify RED**

```powershell
flutter test test\features\background\daily_insight_worker_test.dart
```

Expected: fail because notification body is still generic.

- [x] **Step 3: Add notification API**

Modify `lib/features/notifications/notification_service.dart`:

```dart
Future<void> scheduleDailyReflection({
  required int hour,
  required int minute,
  required String reflectionTitle,
}) {
  _validateTime(hour: hour, minute: minute);
  return _adapter.scheduleDaily(
    id: dailyInsightNotificationId,
    hour: hour,
    minute: minute,
    title: '어제 하루를 정리했어요',
    body: reflectionTitle,
  );
}
```

Keep `scheduleDailyInsight` as a compatibility wrapper:

```dart
Future<void> scheduleDailyInsight({required int hour, required int minute}) {
  return scheduleDailyReflection(
    hour: hour,
    minute: minute,
    reflectionTitle: '어떤 흐름이었는지 가볍게 확인해 보세요.',
  );
}
```

- [x] **Step 4: Use strongest reflection from processor**

In `DailyInsightProcessor._finishRetentionAndNotifications`, accept `String? strongestReflectionTitle`.

When notifications are enabled:

```dart
await _notificationService.scheduleDailyReflection(
  hour: _settings.notificationHour,
  minute: _settings.notificationMinute,
  reflectionTitle: strongestReflectionTitle ?? '어떤 흐름이었는지 가볍게 확인해 보세요.',
);
```

Pass `insights.firstOrNull?.title` from `run`.

- [x] **Step 5: Run notification/background tests**

```powershell
flutter test test\features\notifications\notification_service_test.dart test\features\background\daily_insight_worker_test.dart
```

Expected: pass.

- [x] **Step 6: Commit**

```powershell
git add lib\features\notifications\notification_service.dart lib\features\background\daily_insight_worker.dart test\features\notifications\notification_service_test.dart test\features\background\daily_insight_worker_test.dart
git commit -m "Send strongest reflection in daily notification"
```

---

### Task 6: Add Device Diagnostics For Real Validation

**Files:**
- Create: `lib/features/diagnostics/diagnostics_snapshot.dart`
- Create: `lib/features/diagnostics/diagnostics_repository.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Create: `test/features/diagnostics/diagnostics_repository_test.dart`
- Modify: `test/widget_test.dart`
- Modify: `.docs/status/2026-04-27-android-device-validation.md`

- [ ] **Step 1: Write diagnostics repository test**

Create `test/features/diagnostics/diagnostics_repository_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/diagnostics/diagnostics_repository.dart';
import 'package:projectapp_1/features/storage/app_database.dart';

void main() {
  test('reports last point and stored counts', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.into(database.locationPoints).insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 27, 9),
            latitude: 37,
            longitude: 127,
            accuracy: 20,
          ),
        );

    final snapshot = await DiagnosticsRepository(database).load();

    expect(snapshot.locationPointCount, 1);
    expect(snapshot.lastPointTimeLabel, '2026-04-27 09:00');
  });
}
```

- [ ] **Step 2: Run test to verify RED**

```powershell
flutter test test\features\diagnostics\diagnostics_repository_test.dart
```

Expected: compile failure because diagnostics repository does not exist.

- [ ] **Step 3: Implement diagnostics snapshot and repository**

Create `lib/features/diagnostics/diagnostics_snapshot.dart`:

```dart
class DiagnosticsSnapshot {
  const DiagnosticsSnapshot({
    required this.locationPointCount,
    required this.visitCount,
    required this.reflectionCount,
    required this.lastPointTimeLabel,
  });

  final int locationPointCount;
  final int visitCount;
  final int reflectionCount;
  final String lastPointTimeLabel;
}
```

Create `lib/features/diagnostics/diagnostics_repository.dart`:

```dart
import '../storage/app_database.dart';
import 'diagnostics_snapshot.dart';

class DiagnosticsRepository {
  const DiagnosticsRepository(this._database);

  final AppDatabase _database;

  Future<DiagnosticsSnapshot> load() async {
    final points = await _database.select(_database.locationPoints).get()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final visits = await _database.select(_database.visits).get();
    final reflections = await _database.select(_database.insights).get();
    return DiagnosticsSnapshot(
      locationPointCount: points.length,
      visitCount: visits.length,
      reflectionCount: reflections.length,
      lastPointTimeLabel:
          points.isEmpty ? '아직 없음' : _dateTimeLabel(points.first.timestamp),
    );
  }

  String _dateTimeLabel(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day $hour:$minute';
  }
}
```

- [ ] **Step 4: Add diagnostics section to Settings**

Render a collapsed or simple card:

```dart
_DiagnosticsCard(database: widget.dependencies.database)
```

The card text:

- `기록 상태 확인`
- `저장된 위치 기록 n개`
- `마지막 기록 2026-04-27 09:00`
- `방문 n개 · 돌아보기 n개`

- [ ] **Step 5: Update validation doc**

Modify `.docs/status/2026-04-27-android-device-validation.md` checklist wording:

```markdown
- [ ] Settings diagnostics shows last stored point after tracking is enabled.
- [ ] Settings diagnostics visit/reflection counts increase after daily processing.
```

- [ ] **Step 6: Run diagnostics and widget tests**

```powershell
flutter test test\features\diagnostics\diagnostics_repository_test.dart test\widget_test.dart
```

Expected: pass.

- [ ] **Step 7: Commit**

```powershell
git add lib\features\diagnostics lib\features\settings\settings_screen.dart test\features\diagnostics test\widget_test.dart .docs\status\2026-04-27-android-device-validation.md
git commit -m "Add device validation diagnostics"
```

---

### Task 7: Physical Android Validation Pass

**Files:**
- Modify: `.docs/status/2026-04-27-android-device-validation.md`

- [ ] **Step 1: Build and install debug APK**

Run:

```powershell
flutter build apk --debug
flutter install
```

Expected: app installs on connected Android device.

- [ ] **Step 2: Validate permissions and service**

Manual checks:

- App launches.
- Foreground location permission appears.
- Background location path is understandable.
- `하루 기록` starts foreground service.
- Android foreground notification appears with `하루 기록`.

Record exact result in `.docs/status/2026-04-27-android-device-validation.md`.

- [ ] **Step 3: Validate location event writing**

Use the app for real movement or simulated walking for at least 15 minutes.

Then check:

- Settings diagnostics location point count increases.
- Last point time changes.

Record exact result in `.docs/status/2026-04-27-android-device-validation.md`.

- [ ] **Step 4: Validate daily processing**

Trigger `지금 하루 정리하기`.

Expected states:

- If no yesterday data: app shows `어제 기록이 쌓이면 돌아보기를 만들 수 있어요`.
- If yesterday data exists: visits/reflections increase in diagnostics.
- Today/Reflections/Frequent Places screens refresh.

Record exact result in `.docs/status/2026-04-27-android-device-validation.md`.

- [ ] **Step 5: Validate notification**

Set notification time to a near-future time.

Expected:

- Notification appears.
- Notification title is `어제 하루를 정리했어요`.
- Body contains strongest reflection or fallback body.

Record exact result in `.docs/status/2026-04-27-android-device-validation.md`.

- [ ] **Step 6: Commit validation notes**

```powershell
git add .docs\status\2026-04-27-android-device-validation.md
git commit -m "Record Android device validation results"
```

---

### Task 8: Route Map Evaluation, Not Immediate Build

**Files:**
- Create: `.docs/specs/2026-04-27-route-map-options.md`

- [ ] **Step 1: Write route-map option spec**

Create `.docs/specs/2026-04-27-route-map-options.md`:

```markdown
# Route Map Options

## Decision

Do not add a map dependency until place clustering, timeline, and real-device tracking are validated.

## Options

1. Static timeline first: no dependency, fastest, enough to validate product value.
2. Flutter map package with offline/lightweight tiles: useful but needs tile source policy.
3. Native Google Maps: best familiarity, but adds API key, setup, and privacy review.

## Recommended Next Step

Build timeline and place reliability first. Revisit map after device validation proves records are reliable.
```

- [ ] **Step 2: Commit**

```powershell
git add .docs\specs\2026-04-27-route-map-options.md
git commit -m "Document route map decision"
```

---

## Verification Before Completion

Run after each implementation task:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Expected:

- `flutter analyze`: no issues.
- `flutter test`: all tests pass.
- `flutter build apk --debug`: APK produced at `build\app\outputs\flutter-apk\app-debug.apk`.

## Recommended Execution Order

1. Task 1: Place clusters real in processing.
2. Task 2: Timeline repository.
3. Task 3: Timeline preview on Today.
4. Task 6: Device diagnostics.
5. Task 7: Physical Android validation.
6. Task 5: Strongest reflection in notification.
7. Task 4: Narrator boundary.
8. Task 8: Route-map decision.

This order deliberately avoids building a map before the underlying movement/place data is trustworthy.
