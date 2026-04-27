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
