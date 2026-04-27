# Blue Ink Emotional UI Spec

## Goal

Change the app from a technical location-tracking MVP into a calmer daily-record experience.

## Approved Direction

- Use the "Blue Ink" visual direction approved in the browser mockup.
- Avoid gradients.
- Keep the app name unresolved; do not introduce a new branded name.
- Use blue-gray surfaces, ink-colored emphasis, soft cards, and wider spacing.
- Replace surveillance/processing language with daily-record language.

## Copy Rules

- Replace "추적" with "기록" or "흐름을 남기다".
- Replace "감지" with "머문 곳" or "새롭게 보인 곳".
- Replace "인사이트" with "돌아보기" or "하루 정리".
- Replace "오늘 처리 실행" with "지금 하루 정리하기".
- Keep privacy reassurance visible on the home screen.

## Visual Rules

- Background: light blue-gray.
- Primary emphasis: dark ink/navy.
- Cards: near-white blue surfaces with thin blue-gray borders.
- Buttons: one dark filled primary button for the main action.
- Lists: rounded cards with subdued subtitles.
- No new dependencies or assets.

## Screens In Scope

- App shell theme and navigation labels.
- Home screen status panel, empty state, and latest reflection card.
- History screen empty and list cards.
- Places screen empty, list, rename dialog copy.
- Settings screen copy, setting tiles, action buttons, confirmation dialogs.
- Generated daily reflection titles/bodies/evidence.
- Notification title/body/channel copy.
- Android native app label and foreground-service notification copy.

## Verification

- Update existing widget and service tests to assert the new language.
- Run `flutter analyze`.
- Run `flutter test`.
- Run `flutter build apk --debug`.
