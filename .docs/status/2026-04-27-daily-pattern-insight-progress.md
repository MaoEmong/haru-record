# Daily Pattern Insight App Progress

Date: 2026-04-27
Branch: `codex/daily-pattern-insight-app`

## Current State

The project has moved from an empty Flutter template to an Android-first daily pattern insight app foundation.

Completed work:

- Project documentation rule added: all project docs live under `.docs/`, with repo-level instructions in `AGENTS.md`.
- Product/design docs added for the daily pattern insight app.
- Android and Flutter dependencies added for location tracking, local storage, notifications, permissions, and background work.
- Android foreground tracking boundary implemented:
  - Native Kotlin foreground location service.
  - Flutter platform-channel service wrapper.
  - Battery-conscious default thresholds.
  - Permission and startup hardening.
- Core app settings implemented:
  - Tracking enabled flag.
  - Notification settings.
  - Movement/stay thresholds.
  - Raw point retention days.
- Drift/SQLite local database implemented:
  - Raw location points.
  - Place clusters.
  - Visits.
  - Daily summaries.
  - Insights.
  - Retention cleanup.
- Place visit detection implemented:
  - Filters low-accuracy and mock points.
  - Detects stays using movement radius and minimum stay duration.
  - Handles antimeridian longitude averaging.
- Daily summary and rule-based insight generation implemented.
- Local daily notification scheduling implemented:
  - Uses inexact scheduling to avoid exact alarm requirements.
  - Uses device-local timezone setup.
  - Can cancel the daily insight notification when notifications are disabled.
- Daily background processing implemented:
  - Imports native Android JSONL location events.
  - Preserves pending events on storage failure.
  - Avoids duplicate imports from leftover snapshot files.
  - Generates yesterday's visits, summary, insights, cleanup, and notification updates through Workmanager.
- App shell implemented:
  - Replaced the default Flutter counter UI.
  - Added bottom navigation for Home, History, Places, and Settings.
  - Added initial real-service wiring for latest insights, history, detected places, settings, tracking start/stop, notification toggle, and manual daily processing.
- Settings controls made editable:
  - Notification time can be edited from Settings.
  - Movement threshold, minimum stay, and raw point retention can be edited from Settings.
- Tracking startup is permission-aware:
  - Settings requests location permission before starting tracking.
  - Missing location permission is reported in-app instead of relying only on native service failure.
  - Notification permission is requested before scheduling notifications from Settings.

Latest completed commit:

```text
49f8bd4 feat: add daily insight background processing
```

## Verification

Last verified after app shell work:

```powershell
flutter test
flutter analyze
```

Result:

- `flutter test`: passed, 39 tests.
- `flutter analyze`: passed, no issues.

Known environment blocker:

```powershell
flutter build apk --debug
```

Currently fails because this machine does not have Android SDK configured:

```text
[!] No Android SDK found. Try setting the ANDROID_HOME environment variable.
```

This is an environment setup issue, not a known Dart/Kotlin code failure.

## Remaining Work

### 1. Finish UI Service Wiring And Controls

Connect UI state to the implemented services.

Required behavior:

- Add safe database cleanup/delete controls.
- Refresh Home/History/Places after manual daily processing or place rename without requiring a full app restart.
- Delete/cleanup controls call retention or database deletion logic safely.

### 2. Android Device Validation

After Android SDK is configured, validate on a physical Android device.

Required checks:

- Debug APK builds.
- App launches on device.
- Foreground/background location permissions work.
- Foreground tracking notification appears.
- Native location events are written and imported.
- Visit detection and insight generation work from real movement/stay data.
- Daily notification appears at the configured local time.
- Retention/delete controls keep the app usable after cleanup.

### 3. Polish And Release Readiness

After real-device validation:

- Update `.docs/plans/2026-04-26-daily-pattern-insight-app.md` checkboxes or add a completion summary.
- Add any device-specific findings to `.docs/status/`.
- Consider replacing the default Flutter counter UI entirely once the app shell lands.
- Decide whether to open a PR or continue feature work on the same branch.

## Resume Notes

- Current branch should remain `codex/daily-pattern-insight-app`.
- The working tree was clean before this status document was added.
- Start next with UI control completion and Android permission/device validation.
- Keep the battery-saving goal central: favor inexact scheduling, threshold-based tracking, local processing, and minimal background work.
- All new project docs should stay under `.docs/`.
