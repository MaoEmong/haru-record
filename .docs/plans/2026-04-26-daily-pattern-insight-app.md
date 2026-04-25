# Daily Pattern Insight App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an Android-first Flutter app that records battery-conscious background location events, stores them locally, summarizes daily visits, generates rule-based insights, and shows/schedules those insights.

**Architecture:** Flutter owns UI, local storage, analysis, settings, and notifications. Android owns the first real background tracking implementation through a native foreground service exposed to Flutter by a platform channel. The tracking boundary remains replaceable through a Dart `LocationTrackingService` interface.

**Tech Stack:** Flutter, Dart, Kotlin, Drift/SQLite, SharedPreferencesAsync, flutter_local_notifications, workmanager, permission_handler, Android Fused Location Provider, Android foreground service.

---

## File Structure

- Modify: `pubspec.yaml` - add runtime and codegen dependencies.
- Modify: `android/app/build.gradle.kts` - add Google Play Services location dependency.
- Modify: `android/app/src/main/AndroidManifest.xml` - add location, notification, boot, and foreground service permissions/service declarations.
- Modify: `android/app/src/main/kotlin/com/example/projectapp_1/MainActivity.kt` - register platform channel methods.
- Create: `android/app/src/main/kotlin/com/example/projectapp_1/tracking/LocationTrackingService.kt` - native Android foreground location service.
- Create: `android/app/src/main/kotlin/com/example/projectapp_1/tracking/TrackingMethodChannel.kt` - platform channel adapter.
- Replace: `lib/main.dart` - app bootstrap and navigation.
- Create: `lib/app/app.dart` - Material app shell.
- Create: `lib/app/app_dependencies.dart` - lightweight dependency container.
- Create: `lib/core/geo/geo_math.dart` - distance and date helpers.
- Create: `lib/features/settings/settings_models.dart` - settings values.
- Create: `lib/features/settings/settings_repository.dart` - SharedPreferences-backed settings.
- Create: `lib/features/storage/app_database.dart` - Drift database tables and DAOs.
- Create: `lib/features/storage/database_factory.dart` - SQLite connection factory.
- Create: `lib/features/storage/retention_service.dart` - raw point cleanup.
- Create: `lib/features/tracking/location_tracking_service.dart` - Dart tracking interface.
- Create: `lib/features/tracking/platform_location_tracking_service.dart` - platform channel implementation.
- Create: `lib/features/tracking/location_event_importer.dart` - imports native background event files into Drift.
- Create: `lib/features/places/place_clustering_service.dart` - local clustering and visit detection.
- Create: `lib/features/analysis/daily_summary_service.dart` - daily summary builder.
- Create: `lib/features/background/daily_insight_worker.dart` - daily import, summary, insight, cleanup, and notification job.
- Create: `lib/features/insights/insight_models.dart` - insight candidates/text models.
- Create: `lib/features/insights/insight_generation_service.dart` - rule-based insight generation.
- Create: `lib/features/notifications/notification_service.dart` - local notification scheduling.
- Create: `lib/features/home/home_screen.dart` - insight-first home.
- Create: `lib/features/history/history_screen.dart` - date-based insight history.
- Create: `lib/features/places/place_management_screen.dart` - place list and rename UI.
- Create: `lib/features/settings/settings_screen.dart` - tracking and retention controls.
- Create: `test/core/geo/geo_math_test.dart`
- Create: `test/features/settings/settings_repository_test.dart`
- Create: `test/features/storage/retention_service_test.dart`
- Create: `test/features/places/place_clustering_service_test.dart`
- Create: `test/features/analysis/daily_summary_service_test.dart`
- Create: `test/features/insights/insight_generation_service_test.dart`
- Create: `test/features/tracking/platform_location_tracking_service_test.dart`
- Create: `test/features/notifications/notification_service_test.dart`
- Update: `test/widget_test.dart` - replace counter test with app shell smoke test.

---

## Task 1: Dependencies And Android Baseline

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/build.gradle.kts`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add Flutter dependencies**

Run:

```powershell
flutter pub add drift drift_flutter sqlite3_flutter_libs path_provider path shared_preferences flutter_local_notifications timezone workmanager permission_handler
```

Run:

```powershell
flutter pub add --dev build_runner drift_dev
```

Expected: `pubspec.yaml` contains the new dependencies and `pubspec.lock` is updated.

- [ ] **Step 2: Add Android location dependency**

Modify `android/app/build.gradle.kts` by adding a dependencies block after the `flutter` block:

```kotlin
dependencies {
    implementation("com.google.android.gms:play-services-location:21.3.0")
    implementation("androidx.work:work-runtime-ktx:2.9.1")
}
```

Expected: Gradle can resolve Google Play Services location.

- [ ] **Step 3: Add Android permissions and foreground service declaration**

Modify `android/app/src/main/AndroidManifest.xml` so the top of the manifest includes:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

Inside `<application>`, add:

```xml
<service
    android:name=".tracking.LocationTrackingService"
    android:enabled="true"
    android:exported="false"
    android:foregroundServiceType="location" />
```

Expected: Android recognizes the native foreground location service.

- [ ] **Step 4: Verify dependency resolution**

Run:

```powershell
flutter pub get
```

Expected: command exits 0.

- [ ] **Step 5: Commit**

```powershell
git add pubspec.yaml pubspec.lock android/app/build.gradle.kts android/app/src/main/AndroidManifest.xml
git commit -m "chore: add location app dependencies"
```

---

## Task 2: Core Geo And Settings

**Files:**
- Create: `lib/core/geo/geo_math.dart`
- Create: `lib/features/settings/settings_models.dart`
- Create: `lib/features/settings/settings_repository.dart`
- Create: `test/core/geo/geo_math_test.dart`
- Create: `test/features/settings/settings_repository_test.dart`

- [ ] **Step 1: Write geo math tests**

Create `test/core/geo/geo_math_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/core/geo/geo_math.dart';

void main() {
  test('distanceMeters returns near-zero for identical coordinates', () {
    expect(distanceMeters(37.5665, 126.9780, 37.5665, 126.9780), lessThan(1));
  });

  test('distanceMeters estimates Seoul city hall to Gangnam over 8000 meters', () {
    final distance = distanceMeters(37.5665, 126.9780, 37.4979, 127.0276);
    expect(distance, greaterThan(8000));
    expect(distance, lessThan(12000));
  });
}
```

- [ ] **Step 2: Run geo test and confirm it fails**

Run:

```powershell
flutter test test/core/geo/geo_math_test.dart
```

Expected: FAIL because `geo_math.dart` does not exist.

- [ ] **Step 3: Implement geo math**

Create `lib/core/geo/geo_math.dart`:

```dart
import 'dart:math' as math;

const double earthRadiusMeters = 6371000;

double distanceMeters(
  double startLatitude,
  double startLongitude,
  double endLatitude,
  double endLongitude,
) {
  final startLat = _toRadians(startLatitude);
  final endLat = _toRadians(endLatitude);
  final deltaLat = _toRadians(endLatitude - startLatitude);
  final deltaLng = _toRadians(endLongitude - startLongitude);

  final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
      math.cos(startLat) *
          math.cos(endLat) *
          math.sin(deltaLng / 2) *
          math.sin(deltaLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusMeters * c;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
```

- [ ] **Step 4: Write settings repository tests**

Create `test/features/settings/settings_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/settings/settings_models.dart';
import 'package:projectapp_1/features/settings/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads battery-saving defaults', () async {
    final repository = SettingsRepository();
    final settings = await repository.load();

    expect(settings.trackingEnabled, isFalse);
    expect(settings.notificationEnabled, isTrue);
    expect(settings.notificationHour, 9);
    expect(settings.minimumMovementMeters, 100);
    expect(settings.minimumStayMinutes, 10);
    expect(settings.rawPointRetentionDays, 30);
  });

  test('saves and reloads settings', () async {
    final repository = SettingsRepository();
    const updated = AppSettings(
      trackingEnabled: true,
      notificationEnabled: false,
      notificationHour: 8,
      notificationMinute: 30,
      minimumMovementMeters: 150,
      minimumStayMinutes: 15,
      rawPointRetentionDays: 14,
    );

    await repository.save(updated);
    final loaded = await repository.load();

    expect(loaded, updated);
  });
}
```

- [ ] **Step 5: Implement settings models**

Create `lib/features/settings/settings_models.dart`:

```dart
class AppSettings {
  const AppSettings({
    required this.trackingEnabled,
    required this.notificationEnabled,
    required this.notificationHour,
    required this.notificationMinute,
    required this.minimumMovementMeters,
    required this.minimumStayMinutes,
    required this.rawPointRetentionDays,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      trackingEnabled: false,
      notificationEnabled: true,
      notificationHour: 9,
      notificationMinute: 0,
      minimumMovementMeters: 100,
      minimumStayMinutes: 10,
      rawPointRetentionDays: 30,
    );
  }

  final bool trackingEnabled;
  final bool notificationEnabled;
  final int notificationHour;
  final int notificationMinute;
  final int minimumMovementMeters;
  final int minimumStayMinutes;
  final int rawPointRetentionDays;

  AppSettings copyWith({
    bool? trackingEnabled,
    bool? notificationEnabled,
    int? notificationHour,
    int? notificationMinute,
    int? minimumMovementMeters,
    int? minimumStayMinutes,
    int? rawPointRetentionDays,
  }) {
    return AppSettings(
      trackingEnabled: trackingEnabled ?? this.trackingEnabled,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
      minimumMovementMeters:
          minimumMovementMeters ?? this.minimumMovementMeters,
      minimumStayMinutes: minimumStayMinutes ?? this.minimumStayMinutes,
      rawPointRetentionDays:
          rawPointRetentionDays ?? this.rawPointRetentionDays,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.trackingEnabled == trackingEnabled &&
        other.notificationEnabled == notificationEnabled &&
        other.notificationHour == notificationHour &&
        other.notificationMinute == notificationMinute &&
        other.minimumMovementMeters == minimumMovementMeters &&
        other.minimumStayMinutes == minimumStayMinutes &&
        other.rawPointRetentionDays == rawPointRetentionDays;
  }

  @override
  int get hashCode => Object.hash(
        trackingEnabled,
        notificationEnabled,
        notificationHour,
        notificationMinute,
        minimumMovementMeters,
        minimumStayMinutes,
        rawPointRetentionDays,
      );
}
```

- [ ] **Step 6: Implement settings repository**

Create `lib/features/settings/settings_repository.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_models.dart';

class SettingsRepository {
  static const _trackingEnabled = 'trackingEnabled';
  static const _notificationEnabled = 'notificationEnabled';
  static const _notificationHour = 'notificationHour';
  static const _notificationMinute = 'notificationMinute';
  static const _minimumMovementMeters = 'minimumMovementMeters';
  static const _minimumStayMinutes = 'minimumStayMinutes';
  static const _rawPointRetentionDays = 'rawPointRetentionDays';

  Future<AppSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    final defaults = AppSettings.defaults();
    return AppSettings(
      trackingEnabled:
          preferences.getBool(_trackingEnabled) ?? defaults.trackingEnabled,
      notificationEnabled: preferences.getBool(_notificationEnabled) ??
          defaults.notificationEnabled,
      notificationHour:
          preferences.getInt(_notificationHour) ?? defaults.notificationHour,
      notificationMinute: preferences.getInt(_notificationMinute) ??
          defaults.notificationMinute,
      minimumMovementMeters: preferences.getInt(_minimumMovementMeters) ??
          defaults.minimumMovementMeters,
      minimumStayMinutes: preferences.getInt(_minimumStayMinutes) ??
          defaults.minimumStayMinutes,
      rawPointRetentionDays: preferences.getInt(_rawPointRetentionDays) ??
          defaults.rawPointRetentionDays,
    );
  }

  Future<void> save(AppSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_trackingEnabled, settings.trackingEnabled);
    await preferences.setBool(
      _notificationEnabled,
      settings.notificationEnabled,
    );
    await preferences.setInt(_notificationHour, settings.notificationHour);
    await preferences.setInt(_notificationMinute, settings.notificationMinute);
    await preferences.setInt(
      _minimumMovementMeters,
      settings.minimumMovementMeters,
    );
    await preferences.setInt(_minimumStayMinutes, settings.minimumStayMinutes);
    await preferences.setInt(
      _rawPointRetentionDays,
      settings.rawPointRetentionDays,
    );
  }
}
```

- [ ] **Step 7: Run tests**

Run:

```powershell
flutter test test/core/geo/geo_math_test.dart test/features/settings/settings_repository_test.dart
```

Expected: PASS.

- [ ] **Step 8: Commit**

```powershell
git add lib/core/geo/geo_math.dart lib/features/settings/settings_models.dart lib/features/settings/settings_repository.dart test/core/geo/geo_math_test.dart test/features/settings/settings_repository_test.dart
git commit -m "feat: add geo helpers and app settings"
```

---

## Task 3: Drift Local Database And Retention

**Files:**
- Create: `lib/features/storage/app_database.dart`
- Create: `lib/features/storage/database_factory.dart`
- Create: `lib/features/storage/retention_service.dart`
- Create: `test/features/storage/retention_service_test.dart`

- [ ] **Step 1: Create database schema**

Create `lib/features/storage/app_database.dart` with Drift tables for `location_points`, `place_clusters`, `visits`, `daily_summaries`, and `insights`. Use `DateTimeColumn` for timestamps and `TextColumn` for serialized insight evidence.

Core table names and required fields:

```dart
class LocationPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracy => real()();
  RealColumn get speed => real().nullable()();
  BoolColumn get isMock => boolean().withDefault(const Constant(false))();
  TextColumn get source => text().withDefault(const Constant('android'))();
}
```

Add matching tables for the other data models from the design doc.

- [ ] **Step 2: Create database factory**

Create `lib/features/storage/database_factory.dart`:

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

LazyDatabase openAppDatabaseConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'daily_pattern.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

- [ ] **Step 3: Run code generation**

Run:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/features/storage/app_database.g.dart` is generated.

- [ ] **Step 4: Write retention test**

Create `test/features/storage/retention_service_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/storage/app_database.dart';
import 'package:projectapp_1/features/storage/retention_service.dart';

void main() {
  test('deletes old raw points but keeps summaries and insights', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final now = DateTime(2026, 4, 26, 9);
    await database.into(database.locationPoints).insert(
          LocationPointsCompanion.insert(
            timestamp: now.subtract(const Duration(days: 31)),
            latitude: 37.1,
            longitude: 127.1,
            accuracy: 20,
          ),
        );
    await database.into(database.locationPoints).insert(
          LocationPointsCompanion.insert(
            timestamp: now.subtract(const Duration(days: 1)),
            latitude: 37.2,
            longitude: 127.2,
            accuracy: 20,
          ),
        );
    await database.into(database.dailySummaries).insert(
          DailySummariesCompanion.insert(
            date: DateTime(2026, 4, 25),
            totalDistanceMeters: 1000,
            movingMinutes: 30,
            stationaryMinutes: 600,
            visitCount: 2,
            newPlaceCount: 0,
          ),
        );

    final service = RetentionService(database);
    await service.deleteRawPointsOlderThan(now, retentionDays: 30);

    final points = await database.select(database.locationPoints).get();
    final summaries = await database.select(database.dailySummaries).get();
    expect(points, hasLength(1));
    expect(summaries, hasLength(1));
  });
}
```

- [ ] **Step 5: Implement retention service**

Create `lib/features/storage/retention_service.dart`:

```dart
import 'package:drift/drift.dart';

import 'app_database.dart';

class RetentionService {
  RetentionService(this._database);

  final AppDatabase _database;

  Future<int> deleteRawPointsOlderThan(
    DateTime now, {
    required int retentionDays,
  }) {
    final cutoff = now.subtract(Duration(days: retentionDays));
    return (_database.delete(_database.locationPoints)
          ..where((point) => point.timestamp.isSmallerThanValue(cutoff)))
        .go();
  }
}
```

- [ ] **Step 6: Run storage test**

Run:

```powershell
flutter test test/features/storage/retention_service_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit**

```powershell
git add lib/features/storage test/features/storage
git commit -m "feat: add local database and retention cleanup"
```

---

## Task 4: Native Android Tracking Boundary

**Files:**
- Create: `lib/features/tracking/location_tracking_service.dart`
- Create: `lib/features/tracking/platform_location_tracking_service.dart`
- Create: `test/features/tracking/platform_location_tracking_service_test.dart`
- Modify: `android/app/src/main/kotlin/com/example/projectapp_1/MainActivity.kt`
- Create: `android/app/src/main/kotlin/com/example/projectapp_1/tracking/TrackingMethodChannel.kt`
- Create: `android/app/src/main/kotlin/com/example/projectapp_1/tracking/LocationTrackingService.kt`

- [ ] **Step 1: Write Dart platform service test**

Create `test/features/tracking/platform_location_tracking_service_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/settings/settings_models.dart';
import 'package:projectapp_1/features/tracking/platform_location_tracking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('daily_pattern/tracking');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'isTracking') return false;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('startTracking sends configured thresholds', () async {
    final service = PlatformLocationTrackingService(channel: channel);

    await service.startTracking(AppSettings.defaults());

    expect(calls.single.method, 'startTracking');
    expect(calls.single.arguments['minimumMovementMeters'], 100);
    expect(calls.single.arguments['minimumStayMinutes'], 10);
  });
}
```

- [ ] **Step 2: Implement Dart tracking interface**

Create `lib/features/tracking/location_tracking_service.dart`:

```dart
import '../settings/settings_models.dart';

abstract interface class LocationTrackingService {
  Future<void> startTracking(AppSettings settings);
  Future<void> stopTracking();
  Future<bool> isTracking();
}
```

- [ ] **Step 3: Implement platform channel tracking service**

Create `lib/features/tracking/platform_location_tracking_service.dart`:

```dart
import 'package:flutter/services.dart';

import '../settings/settings_models.dart';
import 'location_tracking_service.dart';

class PlatformLocationTrackingService implements LocationTrackingService {
  PlatformLocationTrackingService({
    MethodChannel channel = const MethodChannel('daily_pattern/tracking'),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<void> startTracking(AppSettings settings) {
    return _channel.invokeMethod<void>('startTracking', {
      'minimumMovementMeters': settings.minimumMovementMeters,
      'minimumStayMinutes': settings.minimumStayMinutes,
    });
  }

  @override
  Future<void> stopTracking() {
    return _channel.invokeMethod<void>('stopTracking');
  }

  @override
  Future<bool> isTracking() async {
    return await _channel.invokeMethod<bool>('isTracking') ?? false;
  }
}
```

- [ ] **Step 4: Implement Kotlin channel adapter**

Create `android/app/src/main/kotlin/com/example/projectapp_1/tracking/TrackingMethodChannel.kt`:

```kotlin
package com.example.projectapp_1.tracking

import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class TrackingMethodChannel(private val context: Context) {
    fun register(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "daily_pattern/tracking"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startTracking" -> {
                    val movement = call.argument<Int>("minimumMovementMeters") ?: 100
                    val stay = call.argument<Int>("minimumStayMinutes") ?: 10
                    val intent = Intent(context, LocationTrackingService::class.java)
                        .putExtra("minimumMovementMeters", movement)
                        .putExtra("minimumStayMinutes", stay)
                    ContextCompat.startForegroundService(context, intent)
                    result.success(null)
                }
                "stopTracking" -> {
                    context.stopService(Intent(context, LocationTrackingService::class.java))
                    result.success(null)
                }
                "isTracking" -> result.success(LocationTrackingService.isRunning)
                "getEventFilePath" -> {
                    result.success(LocationTrackingService.eventFile(context).absolutePath)
                }
                else -> result.notImplemented()
            }
        }
    }
}
```

- [ ] **Step 5: Register channel in MainActivity**

Modify `android/app/src/main/kotlin/com/example/projectapp_1/MainActivity.kt`:

```kotlin
package com.example.projectapp_1

import com.example.projectapp_1.tracking.TrackingMethodChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        TrackingMethodChannel(this).register(flutterEngine)
    }
}
```

- [ ] **Step 6: Implement native foreground service**

Create `android/app/src/main/kotlin/com/example/projectapp_1/tracking/LocationTrackingService.kt` with:

- notification channel id `daily_pattern_tracking`
- foreground notification id `1001`
- Fused Location Provider request with `Priority.PRIORITY_BALANCED_POWER_ACCURACY`
- distance threshold passed from the channel
- structured logging for received locations
- append each received location as one JSON object line to `File(filesDir, "location_events.jsonl")` with keys `timestamp`, `latitude`, `longitude`, `accuracy`, `speed`, `isMock`, and `source`
- companion object method `fun eventFile(context: Context): File = File(context.filesDir, "location_events.jsonl")`

The service must call `startForeground(...)` before requesting location updates.

- [ ] **Step 7: Run Dart tracking test**

Run:

```powershell
flutter test test/features/tracking/platform_location_tracking_service_test.dart
```

Expected: PASS.

- [ ] **Step 8: Run Android debug build**

Run:

```powershell
flutter build apk --debug
```

Expected: PASS.

- [ ] **Step 9: Commit**

```powershell
git add lib/features/tracking test/features/tracking android/app/src/main/kotlin/com/example/projectapp_1 android/app/src/main/AndroidManifest.xml
git commit -m "feat: add android tracking service boundary"
```

---

## Task 5: Place Clustering And Visit Detection

**Files:**
- Create: `lib/features/places/place_clustering_service.dart`
- Create: `test/features/places/place_clustering_service_test.dart`

- [ ] **Step 1: Write clustering tests**

Create `test/features/places/place_clustering_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/places/place_clustering_service.dart';

void main() {
  test('creates a visit when points stay near the same place long enough', () {
    final service = PlaceClusteringService(
      clusterRadiusMeters: 120,
      minimumStayMinutes: 10,
    );
    final start = DateTime(2026, 4, 25, 10);

    final result = service.detectVisits([
      TrackedPoint(start, 37.5665, 126.9780, 20, false),
      TrackedPoint(start.add(const Duration(minutes: 5)), 37.5666, 126.9781, 20, false),
      TrackedPoint(start.add(const Duration(minutes: 11)), 37.5667, 126.9781, 20, false),
    ]);

    expect(result, hasLength(1));
    expect(result.single.durationMinutes, 11);
  });

  test('ignores short stays', () {
    final service = PlaceClusteringService(
      clusterRadiusMeters: 120,
      minimumStayMinutes: 10,
    );
    final start = DateTime(2026, 4, 25, 10);

    final result = service.detectVisits([
      TrackedPoint(start, 37.5665, 126.9780, 20, false),
      TrackedPoint(start.add(const Duration(minutes: 3)), 37.5666, 126.9781, 20, false),
    ]);

    expect(result, isEmpty);
  });
}
```

- [ ] **Step 2: Implement clustering service**

Create `lib/features/places/place_clustering_service.dart`:

```dart
import '../../core/geo/geo_math.dart';

class TrackedPoint {
  const TrackedPoint(
    this.timestamp,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.isMock,
  );

  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double accuracy;
  final bool isMock;
}

class DetectedVisit {
  const DetectedVisit({
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
    required this.latitude,
    required this.longitude,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final int durationMinutes;
  final double latitude;
  final double longitude;
}

class PlaceClusteringService {
  const PlaceClusteringService({
    required this.clusterRadiusMeters,
    required this.minimumStayMinutes,
  });

  final double clusterRadiusMeters;
  final int minimumStayMinutes;

  List<DetectedVisit> detectVisits(List<TrackedPoint> points) {
    if (points.length < 2) return const [];
    final sorted = [...points]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final visits = <DetectedVisit>[];
    var windowStart = sorted.first;
    final window = <TrackedPoint>[windowStart];

    for (final point in sorted.skip(1)) {
      final distance = distanceMeters(
        windowStart.latitude,
        windowStart.longitude,
        point.latitude,
        point.longitude,
      );
      if (distance <= clusterRadiusMeters) {
        window.add(point);
        continue;
      }
      _addVisitIfLongEnough(window, visits);
      window
        ..clear()
        ..add(point);
      windowStart = point;
    }

    _addVisitIfLongEnough(window, visits);
    return visits;
  }

  void _addVisitIfLongEnough(
    List<TrackedPoint> window,
    List<DetectedVisit> visits,
  ) {
    if (window.length < 2) return;
    final start = window.first.timestamp;
    final end = window.last.timestamp;
    final duration = end.difference(start).inMinutes;
    if (duration < minimumStayMinutes) return;

    visits.add(
      DetectedVisit(
        startedAt: start,
        endedAt: end,
        durationMinutes: duration,
        latitude: window.map((p) => p.latitude).reduce((a, b) => a + b) / window.length,
        longitude: window.map((p) => p.longitude).reduce((a, b) => a + b) / window.length,
      ),
    );
  }
}
```

- [ ] **Step 3: Run clustering tests**

Run:

```powershell
flutter test test/features/places/place_clustering_service_test.dart
```

Expected: PASS.

- [ ] **Step 4: Commit**

```powershell
git add lib/features/places test/features/places
git commit -m "feat: detect visits from location points"
```

---

## Task 6: Daily Summaries And Rule-Based Insights

**Files:**
- Create: `lib/features/analysis/daily_summary_service.dart`
- Create: `lib/features/insights/insight_models.dart`
- Create: `lib/features/insights/insight_generation_service.dart`
- Create: `test/features/analysis/daily_summary_service_test.dart`
- Create: `test/features/insights/insight_generation_service_test.dart`

- [ ] **Step 1: Write daily summary tests**

Create `test/features/analysis/daily_summary_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/analysis/daily_summary_service.dart';

void main() {
  test('summarizes visits into stationary minutes and visit count', () {
    final service = DailySummaryService();
    final date = DateTime(2026, 4, 25);

    final summary = service.buildSummary(
      date: date,
      visits: [
        VisitSnapshot(durationMinutes: 40, distanceFromPreviousMeters: 0, isNewPlace: false),
        VisitSnapshot(durationMinutes: 20, distanceFromPreviousMeters: 1300, isNewPlace: true),
      ],
    );

    expect(summary.date, date);
    expect(summary.stationaryMinutes, 60);
    expect(summary.visitCount, 2);
    expect(summary.totalDistanceMeters, 1300);
    expect(summary.newPlaceCount, 1);
  });
}
```

- [ ] **Step 2: Implement daily summary service**

Create `lib/features/analysis/daily_summary_service.dart` with `VisitSnapshot`, `DailySummarySnapshot`, and `DailySummaryService.buildSummary(...)` matching the test.

- [ ] **Step 3: Write insight generation tests**

Create `test/features/insights/insight_generation_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/analysis/daily_summary_service.dart';
import 'package:projectapp_1/features/insights/insight_generation_service.dart';

void main() {
  test('generates lower movement insight against baseline', () {
    final service = InsightGenerationService();
    final date = DateTime(2026, 4, 25);

    final insights = service.generate(
      yesterday: DailySummarySnapshot(
        date: date,
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

    expect(insights.first.title, 'Movement was lower than usual');
    expect(insights.first.body, contains('recent average'));
  });
}
```

- [ ] **Step 4: Implement insight models and generator**

Create `lib/features/insights/insight_models.dart` with:

```dart
enum InsightType { movementChange, visitChange, newPlace, longestStay, lowConfidence }
enum InsightSeverity { neutral, notable, important }

class GeneratedInsight {
  const GeneratedInsight({
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
    required this.evidence,
  });

  final InsightType type;
  final InsightSeverity severity;
  final String title;
  final String body;
  final String evidence;
}
```

Create `lib/features/insights/insight_generation_service.dart` to generate at most two strongest insights from movement, visit, and new-place changes.

- [ ] **Step 5: Run analysis and insight tests**

Run:

```powershell
flutter test test/features/analysis/daily_summary_service_test.dart test/features/insights/insight_generation_service_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```powershell
git add lib/features/analysis lib/features/insights test/features/analysis test/features/insights
git commit -m "feat: generate daily summaries and insights"
```

---

## Task 7: Local Notifications

**Files:**
- Create: `lib/features/notifications/notification_service.dart`
- Create: `test/features/notifications/notification_service_test.dart`

- [ ] **Step 1: Write notification scheduling test with fake adapter**

Create `test/features/notifications/notification_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/notifications/notification_service.dart';

void main() {
  test('schedules daily insight notification at configured time', () async {
    final adapter = FakeNotificationAdapter();
    final service = NotificationService(adapter);

    await service.scheduleDailyInsight(hour: 9, minute: 0);

    expect(adapter.scheduledHour, 9);
    expect(adapter.scheduledMinute, 0);
    expect(adapter.title, 'Your daily insight is ready');
  });
}

class FakeNotificationAdapter implements NotificationAdapter {
  int? scheduledHour;
  int? scheduledMinute;
  String? title;

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
  }
}
```

- [ ] **Step 2: Implement notification service boundary**

Create `lib/features/notifications/notification_service.dart`:

```dart
abstract interface class NotificationAdapter {
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  });
}

class NotificationService {
  NotificationService(this._adapter);

  static const dailyInsightNotificationId = 2001;
  final NotificationAdapter _adapter;

  Future<void> scheduleDailyInsight({
    required int hour,
    required int minute,
  }) {
    return _adapter.scheduleDaily(
      id: dailyInsightNotificationId,
      hour: hour,
      minute: minute,
      title: 'Your daily insight is ready',
      body: 'Open the app to review yesterday.',
    );
  }
}
```

- [ ] **Step 3: Add flutter_local_notifications adapter**

Extend `notification_service.dart` with `FlutterLocalNotificationAdapter`. It must initialize Android channel `daily_pattern_insights`, request notification permission where supported, and schedule daily notifications without requiring exact alarm permission.

- [ ] **Step 4: Run notification test**

Run:

```powershell
flutter test test/features/notifications/notification_service_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/features/notifications test/features/notifications
git commit -m "feat: add daily insight notification service"
```

---

## Task 8: Daily Background Worker

**Files:**
- Create: `lib/features/background/daily_insight_worker.dart`
- Create: `lib/features/tracking/location_event_importer.dart`
- Modify: `lib/features/notifications/notification_service.dart`

- [ ] **Step 1: Create location event importer**

Create `lib/features/tracking/location_event_importer.dart`. It must read `location_events.jsonl` from the app documents directory, parse each JSON line into a raw location point insert, skip malformed lines, and truncate the file only after successful database insertion.

Importer contract:

```dart
class LocationEventImportResult {
  const LocationEventImportResult({
    required this.importedCount,
    required this.skippedCount,
  });

  final int importedCount;
  final int skippedCount;
}

class LocationEventImporter {
  LocationEventImporter(
    this._database, {
    MethodChannel channel = const MethodChannel('daily_pattern/tracking'),
  }) : _channel = channel;

  final AppDatabase _database;
  final MethodChannel _channel;

  Future<LocationEventImportResult> importPendingEvents() async {
    final path = await _channel.invokeMethod<String>('getEventFilePath');
    if (path == null || path.isEmpty) {
      return const LocationEventImportResult(importedCount: 0, skippedCount: 0);
    }
    final file = File(path);
    if (!await file.exists()) {
      return const LocationEventImportResult(importedCount: 0, skippedCount: 0);
    }

    final lines = await file.readAsLines();
    var imported = 0;
    var skipped = 0;
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final json = jsonDecode(line) as Map<String, Object?>;
        await _database.into(_database.locationPoints).insert(
              LocationPointsCompanion.insert(
                timestamp: DateTime.parse(json['timestamp']! as String),
                latitude: json['latitude']! as double,
                longitude: json['longitude']! as double,
                accuracy: json['accuracy']! as double,
                speed: Value(json['speed'] as double?),
                isMock: Value(json['isMock'] as bool? ?? false),
                source: Value(json['source'] as String? ?? 'android'),
              ),
            );
        imported++;
      } catch (_) {
        skipped++;
      }
    }

    await file.writeAsString('');
    return LocationEventImportResult(
      importedCount: imported,
      skippedCount: skipped,
    );
  }
}
```

Required imports for this file: `dart:convert`, `dart:io`, `package:drift/drift.dart`, `package:flutter/services.dart`, and the app database file.

- [ ] **Step 2: Create daily worker callback**

Create `lib/features/background/daily_insight_worker.dart` with:

- `const dailyInsightWorkerName = 'dailyInsightWorker'`
- `Future<void> initializeDailyInsightWorker()` to register a periodic WorkManager task
- `@pragma('vm:entry-point') void dailyInsightWorkerDispatcher()` to initialize services in the background isolate
- processing sequence: import events, detect visits, build yesterday summary, generate insights, save top insights, delete expired raw points, schedule/update insight notification

- [ ] **Step 3: Wire worker initialization**

Modify `lib/main.dart` so app startup initializes timezone data, notification service, and WorkManager before `runApp`.

- [ ] **Step 4: Add developer trigger**

Add a diagnostics action in Settings named `Run daily processing now`. It must call the same daily processing use case as the worker. This keeps real-device validation from requiring an overnight wait while still validating the production processing path.

- [ ] **Step 5: Run tests and analyze**

Run:

```powershell
flutter test
flutter analyze
```

Expected: both exit 0.

- [ ] **Step 6: Commit**

```powershell
git add lib/features/background lib/features/tracking/location_event_importer.dart lib/features/notifications lib/main.dart lib/features/settings
git commit -m "feat: add daily insight background processing"
```

---

## Task 9: App Shell And Screens

**Files:**
- Replace: `lib/main.dart`
- Create: `lib/app/app.dart`
- Create: `lib/app/app_dependencies.dart`
- Create: `lib/features/home/home_screen.dart`
- Create: `lib/features/history/history_screen.dart`
- Create: `lib/features/places/place_management_screen.dart`
- Create: `lib/features/settings/settings_screen.dart`
- Update: `test/widget_test.dart`

- [ ] **Step 1: Replace widget smoke test**

Update `test/widget_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/app/app.dart';

void main() {
  testWidgets('shows daily insight app shell', (tester) async {
    await tester.pumpWidget(const DailyPatternApp());

    expect(find.text('Daily Insight'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Places'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Implement app shell**

Create `lib/app/app.dart` with a `MaterialApp` titled `Daily Insight`, using a `NavigationBar` with Home, History, Places, and Settings destinations.

- [ ] **Step 3: Replace main bootstrap**

Replace `lib/main.dart`:

```dart
import 'package:flutter/material.dart';

import 'app/app.dart';

void main() {
  runApp(const DailyPatternApp());
}
```

- [ ] **Step 4: Implement Home screen**

Create `lib/features/home/home_screen.dart` showing:

- app title `Daily Insight`
- tracking status card
- top insight card
- evidence timeline empty state that later renders stored visits

Use concise product UI text. Do not include implementation instructions in visible UI.

- [ ] **Step 5: Implement History, Places, and Settings screens**

Create the three screens with real controls and empty/data-ready states:

- History: date-grouped empty state and sample insight row layout.
- Places: detected places list empty state and rename affordance.
- Settings: switches/sliders/inputs for tracking, notification time, movement distance, stay duration, retention, and delete buttons.

- [ ] **Step 6: Run widget test**

Run:

```powershell
flutter test test/widget_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit**

```powershell
git add lib/main.dart lib/app lib/features/home lib/features/history lib/features/places lib/features/settings/settings_screen.dart test/widget_test.dart
git commit -m "feat: add daily insight app shell"
```

---

## Task 10: Wire Use Cases Into The UI

**Files:**
- Modify: `lib/app/app_dependencies.dart`
- Modify: `lib/features/home/home_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart`
- Modify: `lib/features/places/place_management_screen.dart`

- [ ] **Step 1: Create dependency container**

Create `lib/app/app_dependencies.dart` with lazy instances for:

- `SettingsRepository`
- `PlatformLocationTrackingService`
- `NotificationService`
- `AppDatabase`
- `RetentionService`
- `LocationEventImporter`

Expose dependencies through constructor parameters where screens need them.

- [ ] **Step 2: Connect Settings screen**

Settings must:

- load saved settings on init
- save changed settings
- call `startTracking(settings)` when tracking switch turns on
- call `stopTracking()` when tracking switch turns off
- call retention cleanup or all-data deletion from delete buttons

- [ ] **Step 3: Connect Home screen**

Home must show:

- tracking status from `LocationTrackingService.isTracking()`
- latest generated insight from local database if present
- clear empty state when there is not enough data
- last native event import result in diagnostics

- [ ] **Step 4: Connect Places screen**

Places must:

- query `PlaceCluster` rows
- show display name or `Unnamed place`
- allow renaming and persist the new name

- [ ] **Step 5: Run tests and analyze**

Run:

```powershell
flutter test
flutter analyze
```

Expected: both exit 0.

- [ ] **Step 6: Commit**

```powershell
git add lib/app lib/features
git commit -m "feat: wire app screens to local services"
```

---

## Task 11: Real Android Device Validation

**Files:**
- Modify only the files directly responsible for a failed validation check, then record the checked behavior in the commit message body.
- Update: `.docs/plans/2026-04-26-daily-pattern-insight-app.md` checkboxes as tasks complete.

- [ ] **Step 1: Build debug APK**

Run:

```powershell
flutter build apk --debug
```

Expected: PASS and APK created under `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 2: Install on a real Android device**

Run:

```powershell
flutter devices
flutter run -d <device-id>
```

Expected: app launches on the physical Android device.

- [ ] **Step 3: Verify permission flow**

On device:

- grant foreground location
- grant background location through Android settings
- grant notification permission if prompted
- confirm foreground tracking notification appears when tracking is enabled

Expected: Settings screen shows tracking enabled and diagnostics show `isTracking = true`.

- [ ] **Step 4: Verify background storage**

On device:

- enable tracking
- background the app
- move at least 100 meters or use a controlled real movement test
- reopen the app

Expected: diagnostics show a newer last stored point.

- [ ] **Step 5: Verify visit and insight generation**

On device:

- remain at one place for at least the configured stay duration
- reopen app
- run any available diagnostics action to process visits/summaries if automatic processing has not run yet

Expected: at least one visit, one daily summary, and one rule-based insight are visible.

- [ ] **Step 6: Verify notification scheduling**

Set notification time to a few minutes ahead for validation.

Expected: local insight notification appears around the configured time without exact alarm permission.

- [ ] **Step 7: Verify retention and deletion**

Use Settings delete actions.

Expected:

- raw point deletion removes raw points
- all-data deletion clears insights, visits, places, and summaries
- app remains usable after deletion

- [ ] **Step 8: Commit device fixes**

```powershell
git add .
git commit -m "fix: stabilize android device tracking validation"
```

---

## Self-Review Checklist

- Spec coverage: Android-first tracking, local storage, place clustering, rule-based insights, notifications, settings, retention, and real-device validation are covered.
- Completeness scan: no unresolved planning markers or deferred implementation instructions are allowed in this plan.
- Type consistency: `AppSettings`, `LocationTrackingService`, `PlaceClusteringService`, `DailySummaryService`, `InsightGenerationService`, and `NotificationService` names are stable across tasks.
- Test strategy: core pure-Dart logic is tested first; Android service is validated by debug build and real-device checks.
