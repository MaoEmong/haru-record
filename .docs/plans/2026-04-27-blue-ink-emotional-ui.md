# Blue Ink Emotional UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the approved Blue Ink visual direction and emotional Korean copy across the Flutter daily-record app.

**Architecture:** Keep the existing screen structure and local-data behavior unchanged. Add a small app style helper for shared colors/card decoration, then update screen widgets and generated copy in place.

**Tech Stack:** Flutter Material 3, Dart, existing Drift/SQLite data layer, existing widget/service tests.

---

### Task 1: Lock New Copy In Tests

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `test/features/insights/insight_generation_service_test.dart`
- Modify: `test/features/notifications/notification_service_test.dart`

- [ ] Update shell expectations to `오늘`, `돌아보기`, `자주 간 곳`, `설정`, and `아직 돌아볼 하루가 없어요`.
- [ ] Update settings interactions to tap `지금 하루 정리하기`, `하루 기록`, and emotional status messages.
- [ ] Update generated reflection expectations to use "돌아보기" language instead of "인사이트".
- [ ] Run targeted tests and confirm they fail before production copy changes.

### Task 2: Add Shared Blue Ink Styling

**Files:**
- Create: `lib/app/app_theme.dart`
- Modify: `lib/app/app.dart`

- [ ] Define shared colors: pale blue background, card blue, blue-gray border, ink primary, muted text.
- [ ] Define reusable `softCardDecoration` and `inkCardDecoration`.
- [ ] Replace the current seed-color theme with Blue Ink color scheme.
- [ ] Keep `MaterialApp.title` as the unresolved temporary title `하루 기록`.

### Task 3: Restyle Primary Screens

**Files:**
- Modify: `lib/features/home/home_screen.dart`
- Modify: `lib/features/history/history_screen.dart`
- Modify: `lib/features/places/place_management_screen.dart`
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] Update home status panel to a larger soft card with `오늘의 흐름을 조용히 남기고 있어요`.
- [ ] Update empty states to use rounded cards and quieter copy.
- [ ] Update list items to use shared soft card decoration.
- [ ] Update settings labels and actions to daily-record language.
- [ ] Replace destructive action labels with softer but clear wording.

### Task 4: Update Generated Copy And Native Labels

**Files:**
- Modify: `lib/features/insights/insight_generation_service.dart`
- Modify: `lib/features/notifications/notification_service.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/src/main/kotlin/com/example/projectapp_1/tracking/LocationTrackingService.kt`
- Modify: `android/app/src/main/kotlin/com/example/projectapp_1/tracking/TrackingMethodChannel.kt`

- [ ] Generate reflection copy such as `어제는 조금 조용한 하루였어요`.
- [ ] Update notification copy to `어제 하루를 정리했어요`.
- [ ] Update Android app label and foreground notification copy to match daily-record language.

### Task 5: Verify And Commit

**Files:**
- All modified files above.

- [ ] Run `dart format` on changed Dart files.
- [ ] Run targeted tests.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test`.
- [ ] Run `flutter build apk --debug`.
- [ ] Commit only files changed for this task; exclude pre-existing generated plugin dirt and `.superpowers`.
