# Daily Pattern Insight App Progress

Date: 2026-04-27
Branch: `master`
Latest reviewed commit: `147530f Document route map decision`

## Current State

The app is now a working Android-first MVP for local daily pattern recording
and reflection.

Core capabilities completed:

- Android foreground location recording through a native Kotlin service.
- Runtime location permission flow before tracking startup.
- Background location settings path validated on a physical Android device.
- Local JSONL native event capture and Dart-side import into Drift/SQLite.
- Local database for raw points, places, visits, daily summaries, and insights.
- Visit detection from location points with movement/stay thresholds.
- Persistent place clusters linked from generated visits.
- Today timeline preview from stored visits and places.
- Day detail route summary from History, showing reflection context, visit
  count, movement distance, moving minutes, and ordered place flow.
- Home, History, Places, and Settings tabs with Korean product copy.
- Editable settings for movement threshold, stay threshold, raw point retention,
  and daily notification time.
- Manual `어제 돌아보기 만들기` processing with clear empty-state feedback.
- Diagnostics summary in Settings for location, visit, and reflection counts.
- Safe cleanup actions for raw points and all local data.
- Daily notification scheduling with generated reflection title/body when an
  insight exists, and fallback copy otherwise.
- `InsightNarrator` boundary so future AI wording can replace deterministic
  copy without rewriting insight candidate detection.
- Debug-only validation seed for physical-device generation checks.

Product/design decisions completed:

- Blue Ink visual direction selected and implemented.
- Map dependency deferred for MVP. Route context should first be handled through
  timeline and route summary surfaces.
- Full route-map decision is documented in
  `.docs/specs/2026-04-27-route-map-options.md`.

## Verification

Latest verification run after the current MVP work:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Result:

- `flutter analyze`: passed, no issues.
- `flutter test`: passed, 61 tests.
- `flutter build apk --debug`: passed and produced
  `build\app\outputs\flutter-apk\app-debug.apk`.

Physical-device validation:

- Device: `SM F946N`, Android 16 API 36, `android-arm64`.
- Debug APK installed and launched.
- Foreground/background location permission path verified.
- Foreground service and `하루 기록` tracking notification verified.
- Native location event writing verified.
- Manual processing import verified.
- Debug-seeded yesterday data generated visits, places, summaries, and insights.
- Home, History, and Places rendered generated data after processing.

Details:

- `.docs/status/2026-04-27-android-device-validation.md`

## Remaining Work

### 1. Branding And App Identity

- Decide final app name.
- Replace or remove temporary `하루 기록` Android app label if it is not the
  final name.
- Prepare launcher icon and splash direction.
- Confirm package/application id strategy before release.

### 2. Notification Permission UX

- Physical-device validation covered location permissions and foreground
  service notification behavior.
- The daily reflection notification permission prompt still needs a clean
  first-run device check.
- After that check, refine Settings copy if the permission-denied state feels
  unclear.

### 3. Release Readiness

- Confirm debug-only validation tools are absent from release builds.
- Add release signing configuration when distribution target is known.
- Review privacy/battery copy for store readiness.
- Decide whether raw coordinate export/delete language needs stronger privacy
  framing.

### 4. Optional Map Rendering

- Do not add a map dependency yet.
- A lightweight day detail and route summary now exists.
- Revisit actual map rendering only if the route summary proves insufficient.

### 5. Documentation Cleanup

- Older implementation plans still contain historical step-by-step scaffolding.
- Keep them as execution history, but prefer this status document and the
  Android validation document for current state.

## Resume Notes

- Continue on `master` unless a new feature branch is explicitly requested.
- Do not commit generated desktop plugin file churn unless intentionally
  updating platform registration.
- Keep the app local-first, battery-conscious, and reflective rather than
  surveillance-like.
- Next recommended task: branding/app identity cleanup, because Android system
  permission dialogs currently expose the temporary app label `하루 기록`.
