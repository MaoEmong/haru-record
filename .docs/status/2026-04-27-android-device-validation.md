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

- [ ] App installs and launches.
- [ ] Foreground location permission request appears.
- [ ] Background location permission path is understandable.
- [ ] Tracking switch starts the foreground service.
- [ ] Foreground tracking notification appears.
- [ ] Native location events are written to `location_events.jsonl`.
- [ ] Settings diagnostics shows last stored point after tracking is enabled.
- [ ] Settings diagnostics visit/reflection counts increase after daily processing.
- [ ] `Run daily processing now` imports pending events.
- [ ] Home shows the latest generated insight.
- [ ] History shows generated insights.
- [ ] Places shows detected places after visits are generated.
- [ ] Daily notification is scheduled at the configured local time.
- [ ] Raw point cleanup preserves insights.
- [ ] Full local data delete resets visible data.

## Findings

- Physical-device behavioral validation is still pending.
- The local Android toolchain is available, and debug APK creation is no longer blocked by missing SDK setup.
- Kotlin daemon cache warnings should be watched during future Android builds. If they return as non-zero build failures, disable Kotlin incremental compilation or investigate plugin cache path handling on Windows.
