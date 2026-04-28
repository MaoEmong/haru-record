# Route Map Clustering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add route-map marker clustering and tap-to-zoom without changing the existing route summary semantics.

**Architecture:** Keep route data generation unchanged. Convert the day route map into a controller-backed widget, cluster only dense route point dots, and keep start/end/visit markers visually distinct and counted as before.

**Tech Stack:** Flutter, `flutter_map`, `flutter_map_marker_cluster`, `latlong2`, widget tests.

---

### Task 1: Add Clustering Dependency

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`

- [ ] **Step 1: Add the package**

Run:

```powershell
flutter pub add flutter_map_marker_cluster:^8.2.2
```

Expected: `pubspec.yaml` includes `flutter_map_marker_cluster: ^8.2.2`.

- [ ] **Step 2: Verify package resolution**

Run:

```powershell
flutter pub get
```

Expected: dependency resolution succeeds with current `flutter_map: ^8.3.0`.

### Task 2: Add Tap-To-Zoom Route Map Controller

**Files:**
- Modify: `lib/features/timeline/day_detail_screen.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Convert `_DayRouteMap` to a stateful widget**

Use a `MapController` field in `_DayRouteMapState` and pass it to `FlutterMap(controller: _mapController, ...)`.

- [ ] **Step 2: Add marker tap behavior**

Wrap start/end/visit markers and route point dots with `GestureDetector`.

On tap:

```dart
void _focusPoint(LatLng point) {
  final currentZoom = _mapController.camera.zoom;
  final targetZoom = currentZoom < _focusedRouteZoom ? _focusedRouteZoom : currentZoom + 1;
  _mapController.move(point, targetZoom.clamp(_minimumRouteZoom, _maximumRouteZoom));
}
```

Expected behavior: tapping a marker centers that coordinate and zooms in.

### Task 3: Cluster Dense Route Dots

**Files:**
- Modify: `lib/features/timeline/day_detail_screen.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Replace the route-dot `MarkerLayer`**

Use:

```dart
MarkerClusterLayerWidget(
  options: MarkerClusterLayerOptions(
    maxClusterRadius: 34,
    size: const Size(34, 34),
    markers: routeDotMarkers,
    builder: (context, markers) => _MapRouteCluster(count: markers.length),
  ),
)
```

- [ ] **Step 2: Keep semantic markers separate**

Render start/end/visit markers in the existing `MarkerLayer`, not in the cluster layer.

- [ ] **Step 3: Add cluster tap behavior**

The cluster plugin can zoom clusters by default. If custom handling is needed, use cluster options to zoom toward the cluster center while preserving current map constraints.

### Task 4: Verify

**Files:**
- Test: `test/widget_test.dart`

- [ ] **Step 1: Update widget test**

Assert:

```dart
expect(find.text('지도 핀 3개'), findsOneWidget);
expect(find.byKey(const ValueKey('day-route-point-dot')), findsNWidgets(2));
expect(find.byKey(const ValueKey('day-route-cluster-layer')), findsOneWidget);
```

- [ ] **Step 2: Run focused tests**

Run:

```powershell
flutter test test\widget_test.dart --plain-name "day detail shows route preview from raw points"
```

Expected: test passes.

- [ ] **Step 3: Run full verification**

Run:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Expected: all commands pass.
