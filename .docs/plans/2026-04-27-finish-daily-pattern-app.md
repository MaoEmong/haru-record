# Finish Daily Pattern App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the usable MVP path for the Daily Pattern Flutter app: editable settings, permission-aware tracking startup, refreshable app screens, safe cleanup controls, and Android validation notes.

**Architecture:** Keep the existing dependency-injection shape in `lib/app/app_dependencies.dart`. Add small app-facing services for permission and maintenance behavior, keep screens focused on UI state, and continue using Drift plus existing repositories/services rather than introducing new state-management packages.

**Tech Stack:** Flutter Material 3, Drift/SQLite, `permission_handler`, `shared_preferences`, `flutter_local_notifications`, Workmanager, Android foreground service.

---

## File Structure

- `lib/app/app_dependencies.dart` owns app-wide service wiring and should expose any new app-facing service through constructor injection for tests.
- `lib/app/app.dart` owns the bottom-navigation shell and should provide refresh hooks to selected screens.
- `lib/features/settings/settings_screen.dart` owns settings controls, permission-aware tracking actions, manual daily processing, and maintenance actions.
- `lib/features/settings/settings_models.dart` already validates settings values and should remain the source of valid ranges.
- `lib/features/permissions/app_permission_service.dart` should be created as a small wrapper around `permission_handler`, with a fakeable interface for tests.
- `lib/features/storage/app_maintenance_service.dart` should be created for user-triggered cleanup/delete behavior.
- `lib/features/home/home_screen.dart`, `lib/features/history/history_screen.dart`, and `lib/features/places/place_management_screen.dart` should support explicit refresh without rebuilding the whole app.
- `test/widget_test.dart` should cover the app shell, editable settings, tracking permission behavior, manual processing refresh, and cleanup controls with fake dependencies.
- `.docs/status/2026-04-27-daily-pattern-insight-progress.md` should be updated after each completed task group.

---

### Task 1: Add Editable Settings Controls

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `test/widget_test.dart`
- Modify: `.docs/status/2026-04-27-daily-pattern-insight-progress.md`

- [ ] **Step 1: Write the failing widget test**

Add this test to `test/widget_test.dart`:

```dart
testWidgets('settings screen edits thresholds and notification time', (
  tester,
) async {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);

  await tester.pumpWidget(
    DailyPatternApp(dependencies: _testDependencies(database)),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('movement-threshold-edit')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('number-setting-field')), '250');
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('stay-threshold-edit')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('number-setting-field')), '20');
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('retention-days-edit')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('number-setting-field')), '14');
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('notification-time-edit')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('hour-setting-field')), '8');
  await tester.enterText(find.byKey(const ValueKey('minute-setting-field')), '30');
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  expect(find.text('250 m'), findsOneWidget);
  expect(find.text('20 min'), findsOneWidget);
  expect(find.text('14 days'), findsOneWidget);
  expect(find.text('08:30'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test\widget_test.dart`

Expected: FAIL because keys such as `movement-threshold-edit`, `number-setting-field`, and `notification-time-edit` do not exist.

- [ ] **Step 3: Implement editable numeric rows**

In `lib/features/settings/settings_screen.dart`, replace read-only `_SettingsValueTile` usage with editable rows:

```dart
_EditableSettingsValueTile(
  key: const ValueKey('movement-threshold-edit'),
  title: 'Movement threshold',
  value: '${settings.minimumMovementMeters} m',
  icon: Icons.directions_walk,
  onTap: () => _editNumber(
    title: 'Movement threshold',
    initialValue: settings.minimumMovementMeters,
    suffix: 'm',
    onSave: (value) => _save(
      settings.copyWith(minimumMovementMeters: value),
    ),
  ),
),
_EditableSettingsValueTile(
  key: const ValueKey('stay-threshold-edit'),
  title: 'Minimum stay',
  value: '${settings.minimumStayMinutes} min',
  icon: Icons.timer_outlined,
  onTap: () => _editNumber(
    title: 'Minimum stay',
    initialValue: settings.minimumStayMinutes,
    suffix: 'min',
    onSave: (value) => _save(settings.copyWith(minimumStayMinutes: value)),
  ),
),
_EditableSettingsValueTile(
  key: const ValueKey('retention-days-edit'),
  title: 'Raw point retention',
  value: '${settings.rawPointRetentionDays} days',
  icon: Icons.storage_outlined,
  onTap: () => _editNumber(
    title: 'Raw point retention',
    initialValue: settings.rawPointRetentionDays,
    suffix: 'days',
    onSave: (value) => _save(settings.copyWith(rawPointRetentionDays: value)),
  ),
),
_EditableSettingsValueTile(
  key: const ValueKey('notification-time-edit'),
  title: 'Notification time',
  value:
      '${settings.notificationHour.toString().padLeft(2, '0')}:'
      '${settings.notificationMinute.toString().padLeft(2, '0')}',
  icon: Icons.notifications_active_outlined,
  onTap: () => _editNotificationTime(settings),
),
```

Add helper methods:

```dart
Future<void> _editNumber({
  required String title,
  required int initialValue,
  required String suffix,
  required Future<void> Function(int value) onSave,
}) async {
  final controller = TextEditingController(text: initialValue.toString());
  final value = await showDialog<int>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          key: const ValueKey('number-setting-field'),
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(suffixText: suffix),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              Navigator.of(context).pop(parsed);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
  controller.dispose();
  if (value == null) return;
  await onSave(value);
}

Future<void> _editNotificationTime(AppSettings settings) async {
  final hourController = TextEditingController(
    text: settings.notificationHour.toString(),
  );
  final minuteController = TextEditingController(
    text: settings.notificationMinute.toString(),
  );
  final updated = await showDialog<AppSettings>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Notification time'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('hour-setting-field'),
                controller: hourController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Hour'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const ValueKey('minute-setting-field'),
                controller: minuteController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minute'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final hour = int.tryParse(hourController.text);
              final minute = int.tryParse(minuteController.text);
              if (hour == null || minute == null) {
                Navigator.of(context).pop();
                return;
              }
              Navigator.of(context).pop(
                settings.copyWith(
                  notificationHour: hour,
                  notificationMinute: minute,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
  hourController.dispose();
  minuteController.dispose();
  if (updated == null) return;
  await _save(updated);
}
```

Add this widget:

```dart
class _EditableSettingsValueTile extends StatelessWidget {
  const _EditableSettingsValueTile({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value),
          const SizedBox(width: 8),
          const Icon(Icons.edit_outlined),
        ],
      ),
      onTap: onTap,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test\widget_test.dart`

Expected: PASS for all widget tests.

- [ ] **Step 5: Run full verification**

Run: `flutter analyze`

Expected: `No issues found!`

Run: `flutter test`

Expected: all tests pass.

- [ ] **Step 6: Update status document**

In `.docs/status/2026-04-27-daily-pattern-insight-progress.md`, move editable settings controls from remaining work to completed work.

- [ ] **Step 7: Commit**

```powershell
git add lib/features/settings/settings_screen.dart test/widget_test.dart .docs/status/2026-04-27-daily-pattern-insight-progress.md
git commit -m "Make daily pattern settings editable

Settings were visible but not configurable, blocking real device tuning.
This adds focused edit dialogs for notification time and battery-sensitive
thresholds while preserving the existing settings repository boundary.

Constraint: No new state-management or form dependencies.
Confidence: medium
Scope-risk: narrow
Tested: flutter analyze; flutter test
Not-tested: Android device permission flow"
```

---

### Task 2: Add Permission-Aware Tracking Startup

**Files:**
- Create: `lib/features/permissions/app_permission_service.dart`
- Modify: `lib/app/app_dependencies.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `test/widget_test.dart`
- Modify: `.docs/status/2026-04-27-daily-pattern-insight-progress.md`

- [ ] **Step 1: Write the failing widget test**

Add fake permission service support to `test/widget_test.dart`:

```dart
class _FakePermissionService implements AppPermissionService {
  _FakePermissionService({required this.locationGranted});

  bool locationGranted;
  bool requestedLocation = false;

  @override
  Future<bool> ensureLocationTrackingPermission() async {
    requestedLocation = true;
    return locationGranted;
  }

  @override
  Future<bool> ensureNotificationPermission() async => true;
}
```

Update `_testDependencies` to accept `permissionService` and pass it to `AppDependencies`.

Add this test:

```dart
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

  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('tracking-switch')));
  await tester.pumpAndSettle();

  expect(permissionService.requestedLocation, isTrue);
  expect(trackingService.started, isFalse);
  expect(find.text('Location permission is required'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test\widget_test.dart`

Expected: FAIL because `AppPermissionService` and `permissionService` do not exist.

- [ ] **Step 3: Implement permission service**

Create `lib/features/permissions/app_permission_service.dart`:

```dart
import 'package:permission_handler/permission_handler.dart';

abstract interface class AppPermissionService {
  Future<bool> ensureLocationTrackingPermission();
  Future<bool> ensureNotificationPermission();
}

class PermissionHandlerAppPermissionService implements AppPermissionService {
  const PermissionHandlerAppPermissionService();

  @override
  Future<bool> ensureLocationTrackingPermission() async {
    final fine = await Permission.locationWhenInUse.request();
    if (!fine.isGranted) return false;

    final background = await Permission.locationAlways.status;
    if (background.isDenied || background.isRestricted) {
      await Permission.locationAlways.request();
    }
    return true;
  }

  @override
  Future<bool> ensureNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
}
```

- [ ] **Step 4: Wire permissions into dependencies**

Modify `lib/app/app_dependencies.dart`:

```dart
import '../features/permissions/app_permission_service.dart';
```

Add a field and constructor argument:

```dart
final AppPermissionService permissionService;
```

In `production()` pass:

```dart
permissionService: const PermissionHandlerAppPermissionService(),
```

- [ ] **Step 5: Use permission service in Settings**

In `_toggleTracking`, before `saveTrackingEnabled`, add:

```dart
if (enabled) {
  final granted = await widget.dependencies.permissionService
      .ensureLocationTrackingPermission();
  if (!granted) {
    setState(() {
      _status = 'Location permission is required';
    });
    return;
  }
}
```

In `_toggleNotifications`, before scheduling when `enabled`, add:

```dart
final granted =
    await widget.dependencies.permissionService.ensureNotificationPermission();
if (!granted) {
  setState(() {
    _status = 'Notification permission is required';
  });
  return;
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test\widget_test.dart`

Expected: PASS.

- [ ] **Step 7: Run full verification**

Run: `flutter analyze`

Expected: `No issues found!`

Run: `flutter test`

Expected: all tests pass.

- [ ] **Step 8: Update status document**

In `.docs/status/2026-04-27-daily-pattern-insight-progress.md`, record that tracking startup is now permission-aware, with real-device validation still pending.

- [ ] **Step 9: Commit**

```powershell
git add lib/features/permissions/app_permission_service.dart lib/app/app_dependencies.dart lib/features/settings/settings_screen.dart test/widget_test.dart .docs/status/2026-04-27-daily-pattern-insight-progress.md
git commit -m "Gate tracking startup on runtime permissions

Tracking previously relied on native startup failure to reveal missing
permissions. The Settings flow now requests location permissions before
starting tracking and reports a clear in-app state when permission is absent.

Constraint: Android-specific behavior must stay behind a fakeable interface.
Confidence: medium
Scope-risk: moderate
Tested: flutter analyze; flutter test
Not-tested: Android runtime permission dialogs on device"
```

---

### Task 3: Add Screen Refresh After Manual Processing And Place Rename

**Files:**
- Modify: `lib/app/app.dart`
- Modify: `lib/features/home/home_screen.dart`
- Modify: `lib/features/history/history_screen.dart`
- Modify: `lib/features/places/place_management_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `test/widget_test.dart`

- [ ] **Step 1: Write the failing widget test**

Add this test to `test/widget_test.dart`:

```dart
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
          await database.into(database.insights).insert(
                InsightsCompanion.insert(
                  date: DateTime(2026, 4, 27),
                  type: 'movementChange',
                  severity: 'notable',
                  title: 'Movement was lower than usual',
                  body: 'Yesterday was quieter than your recent average.',
                  evidence: '100m vs 400m recent average',
                  createdAt: DateTime(2026, 4, 27, 9),
                ),
              );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('No insights yet'), findsOneWidget);

  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Run daily processing now'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Home'));
  await tester.pumpAndSettle();

  expect(processingRuns, 1);
  expect(find.text('Movement was lower than usual'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test\widget_test.dart`

Expected: FAIL because `runDailyProcessingNow` is not injectable and Home does not refresh after Settings processing.

- [ ] **Step 3: Make manual processing injectable**

In `lib/app/app_dependencies.dart`, add:

```dart
final Future<void> Function()? runDailyProcessingOverride;
```

Add it as an optional constructor parameter.

Change `runDailyProcessingNow()`:

```dart
Future<void> runDailyProcessingNow() async {
  if (runDailyProcessingOverride != null) {
    await runDailyProcessingOverride!();
    return;
  }
  final settings = await settingsRepository.load();
  final processor = DailyInsightProcessor(
    database: database,
    notificationService: notificationService,
    importPendingEvents: importPendingEvents,
    settings: settings,
  );
  await processor.run(now: DateTime.now());
}
```

- [ ] **Step 4: Add shell-level refresh counter**

In `lib/app/app.dart`, add this field to `_DailyPatternShellState`:

```dart
int _refreshVersion = 0;
```

Pass it to screens:

```dart
HomeScreen(
  dependencies: widget.dependencies,
  refreshVersion: _refreshVersion,
),
HistoryScreen(
  database: widget.dependencies.database,
  refreshVersion: _refreshVersion,
),
PlaceManagementScreen(
  database: widget.dependencies.database,
  refreshVersion: _refreshVersion,
  onPlacesChanged: _refreshAll,
),
SettingsScreen(
  dependencies: widget.dependencies,
  onDataChanged: _refreshAll,
),
```

Add:

```dart
void _refreshAll() {
  setState(() {
    _refreshVersion++;
  });
}
```

- [ ] **Step 5: Refresh screens when version changes**

In Home, History, and Places screens, add `refreshVersion` to constructors. Implement:

```dart
@override
void didUpdateWidget(covariant HomeScreen oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.refreshVersion != widget.refreshVersion) {
    setState(() {
      _snapshot = _load();
    });
  }
}
```

Use the equivalent method in History and Places, updating `_insights` or `_places`.

- [ ] **Step 6: Notify shell after changes**

In `SettingsScreen`, add:

```dart
final VoidCallback? onDataChanged;
```

Call `widget.onDataChanged?.call();` after successful `_runProcessing()`.

In `PlaceManagementScreen`, add:

```dart
final VoidCallback? onPlacesChanged;
```

Call `widget.onPlacesChanged?.call();` after successful rename.

- [ ] **Step 7: Run test to verify it passes**

Run: `flutter test test\widget_test.dart`

Expected: PASS.

- [ ] **Step 8: Run full verification**

Run: `flutter analyze`

Expected: `No issues found!`

Run: `flutter test`

Expected: all tests pass.

- [ ] **Step 9: Commit**

```powershell
git add lib/app/app.dart lib/app/app_dependencies.dart lib/features/home/home_screen.dart lib/features/history/history_screen.dart lib/features/places/place_management_screen.dart lib/features/settings/settings_screen.dart test/widget_test.dart
git commit -m "Refresh app screens after local data changes

Manual processing and place edits should immediately update the visible app
state. A shell-level refresh version keeps the implementation simple without
adding a state-management dependency.

Constraint: No new state-management dependency.
Confidence: medium
Scope-risk: moderate
Tested: flutter analyze; flutter test
Not-tested: Long-running processing on physical device"
```

---

### Task 4: Add Safe Maintenance Controls

**Files:**
- Create: `lib/features/storage/app_maintenance_service.dart`
- Modify: `lib/app/app_dependencies.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `test/widget_test.dart`
- Modify: `.docs/status/2026-04-27-daily-pattern-insight-progress.md`

- [ ] **Step 1: Write the failing widget test**

Add this test to `test/widget_test.dart`:

```dart
testWidgets('settings cleanup removes raw points but keeps insights', (
  tester,
) async {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);

  await database.into(database.locationPoints).insert(
        LocationPointsCompanion.insert(
          timestamp: DateTime(2026, 1, 1),
          latitude: 37,
          longitude: 127,
          accuracy: 20,
        ),
      );
  await database.into(database.insights).insert(
        InsightsCompanion.insert(
          date: DateTime(2026, 4, 27),
          type: 'movementChange',
          severity: 'notable',
          title: 'Existing insight',
          body: 'Kept after raw cleanup.',
          evidence: 'seed data',
          createdAt: DateTime(2026, 4, 27),
        ),
      );

  await tester.pumpWidget(
    DailyPatternApp(dependencies: _testDependencies(database)),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Settings'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete raw location points'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();

  final points = await database.select(database.locationPoints).get();
  final insights = await database.select(database.insights).get();
  expect(points, isEmpty);
  expect(insights, hasLength(1));
  expect(find.text('Raw location points deleted'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test\widget_test.dart`

Expected: FAIL because the maintenance service and delete button do not exist.

- [ ] **Step 3: Implement maintenance service**

Create `lib/features/storage/app_maintenance_service.dart`:

```dart
import 'app_database.dart';

class AppMaintenanceService {
  const AppMaintenanceService(this._database);

  final AppDatabase _database;

  Future<void> deleteRawLocationPoints() async {
    await _database.delete(_database.locationPoints).go();
  }

  Future<void> deleteAllLocalData() async {
    await _database.transaction(() async {
      await _database.delete(_database.insights).go();
      await _database.delete(_database.dailySummaries).go();
      await _database.delete(_database.visits).go();
      await _database.delete(_database.placeClusters).go();
      await _database.delete(_database.locationPoints).go();
    });
  }
}
```

- [ ] **Step 4: Wire service into dependencies**

In `lib/app/app_dependencies.dart`, import:

```dart
import '../features/storage/app_maintenance_service.dart';
```

Add field:

```dart
final AppMaintenanceService maintenanceService;
```

In `production()`, pass:

```dart
maintenanceService: AppMaintenanceService(database),
```

Update tests to pass `AppMaintenanceService(database)` in `_testDependencies`.

- [ ] **Step 5: Add Settings maintenance controls**

In `SettingsScreen`, add buttons:

```dart
OutlinedButton.icon(
  onPressed: _busy ? null : _confirmDeleteRawPoints,
  icon: const Icon(Icons.delete_sweep_outlined),
  label: const Text('Delete raw location points'),
),
const SizedBox(height: 8),
OutlinedButton.icon(
  onPressed: _busy ? null : _confirmDeleteAllLocalData,
  icon: const Icon(Icons.delete_forever_outlined),
  label: const Text('Delete all local data'),
),
```

Add:

```dart
Future<bool> _confirm(String title, String body) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ) ??
      false;
}

Future<void> _confirmDeleteRawPoints() async {
  final confirmed = await _confirm(
    'Delete raw location points',
    'Summaries and insights will stay available.',
  );
  if (!confirmed) return;
  await widget.dependencies.maintenanceService.deleteRawLocationPoints();
  widget.onDataChanged?.call();
  setState(() {
    _status = 'Raw location points deleted';
  });
}

Future<void> _confirmDeleteAllLocalData() async {
  final confirmed = await _confirm(
    'Delete all local data',
    'This removes points, places, visits, summaries, and insights from this device.',
  );
  if (!confirmed) return;
  await widget.dependencies.maintenanceService.deleteAllLocalData();
  widget.onDataChanged?.call();
  setState(() {
    _status = 'All local data deleted';
  });
}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test\widget_test.dart`

Expected: PASS.

- [ ] **Step 7: Run full verification**

Run: `flutter analyze`

Expected: `No issues found!`

Run: `flutter test`

Expected: all tests pass.

- [ ] **Step 8: Update status document**

In `.docs/status/2026-04-27-daily-pattern-insight-progress.md`, record safe local cleanup controls as completed.

- [ ] **Step 9: Commit**

```powershell
git add lib/features/storage/app_maintenance_service.dart lib/app/app_dependencies.dart lib/features/settings/settings_screen.dart test/widget_test.dart .docs/status/2026-04-27-daily-pattern-insight-progress.md
git commit -m "Add safe local data maintenance controls

Users need an explicit way to clear raw location data without losing derived
history, plus a stronger full reset option. The maintenance service keeps
destructive database operations behind confirmable UI actions.

Constraint: Raw cleanup must preserve summaries and insights.
Confidence: medium
Scope-risk: moderate
Tested: flutter analyze; flutter test
Not-tested: Device database behavior after app process restart"
```

---

### Task 5: Android Build And Device Validation Prep

**Files:**
- Modify: `.docs/status/2026-04-27-daily-pattern-insight-progress.md`
- Create: `.docs/status/2026-04-27-android-device-validation.md`
- Possibly modify: `android/app/build.gradle.kts`
- Possibly modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Run Android environment check**

Run: `flutter doctor -v`

Expected if Android SDK is missing: output includes `No Android SDK found` or Android toolchain errors. Record the exact Android section in `.docs/status/2026-04-27-android-device-validation.md`.

- [ ] **Step 2: Try debug APK build**

Run: `flutter build apk --debug`

Expected if Android SDK is configured: `Built build\app\outputs\flutter-apk\app-debug.apk`.

Expected if Android SDK is missing: failure mentioning `ANDROID_HOME`, Android SDK, Gradle Android plugin, or missing Android licenses. Record the exact blocker in `.docs/status/2026-04-27-android-device-validation.md`.

- [ ] **Step 3: Create validation document**

Create `.docs/status/2026-04-27-android-device-validation.md`:

```markdown
# Android Device Validation

Date: 2026-04-27

## Environment

- `flutter doctor -v`: <paste concise Android toolchain result>
- `flutter build apk --debug`: <passed or blocked>

## Device Checks

- [ ] App installs and launches.
- [ ] Foreground location permission request appears.
- [ ] Background location permission path is understandable.
- [ ] Tracking switch starts the foreground service.
- [ ] Foreground tracking notification appears.
- [ ] Native location events are written to `location_events.jsonl`.
- [ ] `Run daily processing now` imports pending events.
- [ ] Home shows the latest generated insight.
- [ ] History shows generated insights.
- [ ] Places shows detected places after visits are generated.
- [ ] Daily notification is scheduled at the configured local time.
- [ ] Raw point cleanup preserves insights.
- [ ] Full local data delete resets visible data.

## Findings

- <record each device issue with reproduction steps and fix commit>
```

Replace `<...>` entries with real command results before committing.

- [ ] **Step 4: Fix build blockers only when they are code issues**

If `flutter build apk --debug` fails due to code, Gradle, manifest, or dependency configuration, fix the specific error and rerun:

Run: `flutter build apk --debug`

Expected: debug APK builds successfully.

If it fails only because Android SDK is absent, do not change code; document the environment blocker.

- [ ] **Step 5: Run full verification**

Run: `flutter analyze`

Expected: `No issues found!`

Run: `flutter test`

Expected: all tests pass.

- [ ] **Step 6: Update progress document**

In `.docs/status/2026-04-27-daily-pattern-insight-progress.md`, link to `.docs/status/2026-04-27-android-device-validation.md` and record whether APK build is passing or blocked by environment.

- [ ] **Step 7: Commit**

```powershell
git add .docs/status/2026-04-27-android-device-validation.md .docs/status/2026-04-27-daily-pattern-insight-progress.md android/app/build.gradle.kts android/app/src/main/AndroidManifest.xml
git commit -m "Document Android validation state

The app now needs device-level proof for permissions, foreground tracking,
background import, and notifications. This records the build/device checklist
and separates environment blockers from code issues.

Constraint: Do not mask missing Android SDK setup with unrelated code changes.
Confidence: medium
Scope-risk: narrow
Tested: flutter analyze; flutter test; flutter build apk --debug or documented environment blocker
Not-tested: Any unchecked physical-device checklist item"
```

---

## Self-Review

- Spec coverage: The plan covers the remaining MVP gaps discussed after the merge: editable settings, runtime permissions, refresh after processing/rename, safe cleanup, Android build/device validation, and docs updates.
- Placeholder scan: No `TBD`, `TODO`, or unspecified "add tests" steps remain. Android validation uses explicit replacement markers only for real command output that cannot be known before execution.
- Type consistency: New interfaces are named `AppPermissionService` and `AppMaintenanceService`; both are injected through `AppDependencies` and used by `SettingsScreen`.
- Scope note: App branding, package id, release signing, icons, and visual polish are intentionally left for a later release-readiness plan after Android device validation proves the core behavior.
