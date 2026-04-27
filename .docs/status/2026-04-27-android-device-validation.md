# Android Device Validation

Date: 2026-04-27

## Environment

- `flutter doctor -v`: passed with no issues.
- Flutter: stable 3.41.7.
- Dart: 3.11.5.
- Android SDK: 36.1.0 at `C:\Users\G\AppData\Local\Android\sdk`.
- Android licenses: accepted.
- Connected Android device: `SM F946N`, Android 16 API 36, `android-arm64`.

## Debug APK Build

- `flutter build apk --debug`: exit code 0.
- Output APK: `build\app\outputs\flutter-apk\app-debug.apk`.
- Last observed APK size: approximately 159 MB.

Build note:

- The debug APK is produced successfully.
- An earlier build printed Kotlin daemon incremental cache errors after the success line.
- After a follow-up `flutter build apk --debug`, the debug APK built cleanly without the Kotlin daemon warning.
- This is recorded as a transient toolchain cache warning to monitor, not as a blocking app code failure.

## Device Checks

- [x] App installs and launches.
- [ ] Foreground location permission request appears.
- [ ] Background location permission path is understandable.
- [x] Tracking switch starts the foreground service.
- [x] Foreground tracking notification appears.
- [x] Native location events are written to `location_events.jsonl`.
- [x] Settings diagnostics shows last stored point after tracking is enabled.
- [ ] Settings diagnostics visit/reflection counts increase after daily processing.
- [x] `어제 돌아보기 만들기` imports pending events.
- [ ] Home shows the latest generated insight.
- [ ] History shows generated insights.
- [ ] Places shows detected places after visits are generated.
- [x] Daily notification is scheduled at the configured local time.
- [x] Raw point cleanup completes from Settings.
- [x] Full local data delete resets visible data.

## Findings

- Physical-device behavioral validation ran on `SM F946N` with the debug APK installed by `adb install -r`.
- `flutter install -d R3CW706M57L` looked for `app-release.apk` unexpectedly, so the debug APK was installed directly from `build\app\outputs\flutter-apk\app-debug.apk`.
- Location and notification permissions were granted with ADB for this run. The clean first-run permission request UX and the Android Settings background-permission path still need manual validation after reinstalling or clearing permissions.
- Starting `LocationTrackingService` directly from ADB is blocked because the service is not exported. That is expected. Starting it through the Settings tracking switch works.
- The foreground service starts with notification channel `daily_pattern_tracking`, foreground id `1001`, and notification title `하루 기록`.
- Native Android location capture wrote a real `location_recorded` event to `files/location_events.jsonl`, including latitude, longitude, accuracy, speed, mock-location flag, and `source: android`.
- Tapping `어제 돌아보기 만들기` imported the pending native event into the app database and cleared the JSONL snapshot file. Settings diagnostics changed to `위치 1개 · 방문 0개 · 돌아보기 0개`.
- The button correctly reported `어제 기록이 아직 없어요. 오늘 기록은 내일 돌아볼 수 있어요` because the captured point was from today, not yesterday.
- The local notification alarm is scheduled through `ScheduledNotificationReceiver` for `2026-04-28 09:00:00.000`.
- Raw point cleanup showed the confirmation dialog and completed with `자세한 위치 기록을 비웠어요`.
- Full local data delete showed the confirmation dialog and completed with `이 기기의 기록을 모두 지웠어요`; visible settings diagnostics no longer show stored counts.
- Home latest insight, History insights, and Places generated-place flows were not produced in this validation run because only a single same-day point was captured. Those require yesterday visit data or injected fixture data.
- The local Android toolchain is available, and debug APK creation is no longer blocked by missing SDK setup.
- Kotlin daemon cache warnings should be watched during future Android builds. If they return as non-zero build failures, disable Kotlin incremental compilation or investigate plugin cache path handling on Windows.
