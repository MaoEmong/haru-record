# 오늘/그날의 흐름 재생 페이지 구현 계획

작성일: 2026-04-30

## 배경

현재 오늘 탭과 하루 상세 페이지에는 시간 스크러버가 있다. 이 스크러버는 하루 전체 `00:00~23:59` 기준으로 동작하기 때문에, 실제 기록 구간이 짧은 날에는 조작감이 둔하다. 예를 들어 기록이 `07:38~08:46`에만 쌓인 날에도 스크러버 대부분은 빈 시간대가 된다.

기존 스크러버는 유지하되, 정밀 탐색은 별도 페이지에서 처리한다. 기존 스크러버는 사용자가 "시간 흐름으로 볼 수 있다"는 것을 알게 하는 티저 역할로 남긴다.

## 확정된 UX 결정

- 새 페이지 이름은 날짜에 따라 다르게 표시한다.
- 오늘 날짜: `오늘의 흐름`
- 과거 날짜: `그날의 흐름`
- 오늘 탭 진입 문구: `오늘의 흐름 보기`
- 상세/돌아보기 상세 진입 문구: `그날의 흐름 보기`
- 오늘 탭/상세 페이지의 간단 스크러버는 유지한다.
- 새 페이지 진입 시 기존 간단 스크러버의 선택 시간은 전달하지 않는다.
- 오늘 날짜로 진입하면 기본값은 현재 시간 기준이며, 실제 선택 좌표는 현재 시간에 가장 가까운 마지막 기록 좌표다.
- 과거 날짜로 진입하면 기본값은 마지막 기록 좌표다.
- 새 페이지의 스크러버는 24시간 기준이 아니라 실제 기록 구간 기준이다.
- 지도는 최초 진입 시 전체 경로가 보이도록 맞춘다.
- 재생 중 지도 카메라는 자동으로 따라가지 않는다.
- 사용자는 재생 중에도 지도를 자유롭게 이동/확대/축소할 수 있다.
- 재생은 좌표 단위로 진행한다.
- 첫 버전 재생 간격은 `0.7초`다.
- 수동 조작(스크러버/이전/다음) 시 재생은 일시정지한다.

## 현재 관련 코드 상태

- `lib/features/timeline/day_route_models.dart`
  - `DayRouteSnapshot.points`: 지도 표시용으로 정리된 위치 좌표.
  - `DayRouteSnapshot.visits`: 방문 지점 마커.
  - `DayRoutePoint`: timestamp, timeLabel, latitude, longitude, accuracyMeters 포함.
- `lib/features/timeline/day_route_repository.dart`
  - 날짜별 raw location points를 읽고 `LocationPostProcessor.cleanRouteDisplayPoints`로 지도 표시용 좌표를 생성한다.
  - GPS 튐/저정확도 좌표는 이미 이 경로에서 정리된다.
- `lib/features/timeline/day_activity_preview_repository.dart`
  - `DayActivityPreview.timeline`을 만든다.
  - persisted visits와 raw points 기반 inferred visits를 병합한다.
- `lib/features/timeline/day_time_selection.dart`
  - 현재 24시간 기준 progress 계산/nearest route point 선택 로직이 있다.
  - 새 페이지를 위해 기록 구간 기준 progress 계산을 여기에 추가하는 것이 적합하다.
- `lib/features/home/home_screen.dart`
  - 오늘 탭 간단 스크러버가 있다.
  - 기본 상태는 현재 시간 표시, 현재 위치 카드는 마지막 기록 좌표를 보여주도록 수정되어 있다.
- `lib/features/timeline/day_detail_screen.dart`
  - 하루 상세/돌아보기 상세 공용 화면이다.
  - 이동 경로 카드와 간단 스크러버가 있다.
  - 이 카드 또는 스크러버를 새 페이지 진입점으로 쓸 수 있다.

## 구현 범위

### 1. 기록 구간 기반 시간 유틸 추가

파일: `lib/features/timeline/day_time_selection.dart`

추가할 개념:

- `RoutePlaybackWindow`
  - `start`: 첫 route point 시간
  - `end`: 오늘이면 현재 시간, 과거면 마지막 route point 시간
  - `duration`
- `progressForPlaybackTime(window, time)`
- `playbackTimeFromProgress(window, progress)`
- `nearestRoutePointIndexForTime(points, time)`
- `playbackWindowForDate(date, points, now)`

주의:

- points가 비어 있으면 window를 만들 수 없다.
- points가 1개면 duration이 0일 수 있으므로 progress는 1 또는 0으로 안전 처리한다.
- 오늘 판단은 `DateTime(now.year, now.month, now.day) == DateTime(date.year, date.month, date.day)` 기준으로 한다.

### 2. 새 화면 추가

파일 후보: `lib/features/timeline/day_flow_playback_screen.dart`

위젯:

- `DayFlowPlaybackScreen`

입력:

- `AppDatabase database`
- `DateTime date`
- `SettingsRepository? settingsRepository`
- `DayActivityPreview? initialPreview`
- `Future<DayRouteSnapshot>? initialRoute`

데이터 로딩:

- 기존 `DayDetailQuery`, `dayDetailPreviewProvider`, `dayDetailRouteProvider`를 재사용하거나 같은 repository를 직접 사용한다.
- 가능하면 중복 provider를 만들지 말고 `DayDetailQuery`를 재사용한다.

상태:

- `int selectedPointIndex`
- `bool isPlaying`
- `Timer? playbackTimer`

초기 선택:

- route points가 비어 있으면 빈 상태.
- 오늘이면 `DateTime.now()`에 가장 가까운 route point.
- 과거면 마지막 route point.

### 3. 지도 UI

지도 동작:

- 전체 경로는 흐리게 표시.
- 선택 지점까지의 경로는 진하게 표시.
- 선택 좌표는 강조 마커.
- 방문 지점은 별도 마커.
- 최초 진입 시 전체 route points + visits가 보이도록 bounds fit.
- 재생/스크러버 조작 시 `MapController.move`를 호출하지 않는다.

주의:

- `isValidCoordinate`로 좌표 검증.
- route points가 2개 미만이면 지도 대신 빈 상태/단일 위치 상태를 보여준다.
- 기존 `DayDetailScreen`의 `_DayRouteMap` 구현을 참고하되, 새 화면 내부 전용 위젯으로 분리하는 것이 안전하다.

### 4. 하단 플레이어 패널

구성:

- 선택 시간
- 기록 범위: `첫 기록 - 현재` 또는 `첫 기록 - 마지막 기록`
- `n / total` 좌표 순번
- 정확도: `정확도 12m`
- 장소 설명:
  - `DayActivityPreview.timeline`에서 선택 시간이 포함되는 item이 있으면 item.placeLabel
  - 없으면 `이동 중 기록`
- 큰 스크러버
- 이전 버튼
- 재생/일시정지 버튼
- 다음 버튼

재생:

- 재생 버튼 클릭 시 `Timer.periodic(Duration(milliseconds: 700))`.
- tick마다 `selectedPointIndex + 1`.
- 마지막 index에 도달하면 `isPlaying = false`, timer cancel.
- 이전/다음/스크러버 조작 시 timer cancel 후 `isPlaying = false`.

### 5. 기존 화면 진입 연결

오늘 탭:

- `HomeScreen`에 `onOpenDayFlow` callback을 추가하거나, 기존 `onOpenTodayRecords`와 별도 callback을 둔다.
- 오늘 탭 스크러버 영역 또는 주변 `오늘의 흐름 보기` 문구를 탭하면 새 페이지로 이동한다.
- 기존 스크러버 조작 자체는 유지한다.

앱 shell:

- `lib/app/app.dart`에 `_openDayFlow(...)` 추가.
- `DayFlowPlaybackScreen`으로 push.

상세/돌아보기 상세:

- `DayDetailScreen`에 `onOpenDayFlow` 또는 내부 push에 필요한 dependencies를 전달할지 결정한다.
- 현재 `DayDetailScreen`은 `database`, `date`, `settingsRepository`, `initialPreview`, `initialRoute`를 이미 가지고 있으므로 내부에서 `Navigator.push`로 `DayFlowPlaybackScreen`을 열 수 있다.
- 이동 경로 카드/지도 영역에 탭 진입을 추가한다.
- 카드에는 `그날의 흐름 보기` 텍스트를 작게 표시한다.

### 6. 테스트 계획

유닛/위젯 테스트:

- `playbackWindowForDate`가 오늘 날짜에서 end를 now로 잡는지.
- 과거 날짜에서 end를 마지막 route point로 잡는지.
- progress 0/0.5/1이 기록 구간 안의 시간으로 변환되는지.
- 빈 route points에서 새 화면이 빈 상태를 표시하는지.
- 새 화면이 route points와 방문 마커를 표시하는지.
- 다음 버튼 클릭 시 selected point가 증가하는지.
- 이전 버튼 클릭 시 selected point가 감소하는지.
- 재생 버튼 클릭 후 시간이 지나면 다음 좌표로 이동하는지.
- 마지막 좌표에서 자동 정지하는지.
- 스크러버 조작 시 가장 가까운 route point로 스냅하는지.
- 오늘 탭에서 `오늘의 흐름 보기` 진입이 동작하는지.
- 상세 페이지에서 `그날의 흐름 보기` 진입이 동작하는지.

검증 명령:

```powershell
flutter analyze
flutter test test\widget_test.dart --plain-name "home opens day flow playback"
flutter test test\widget_test.dart --plain-name "day detail opens day flow playback"
flutter test test\widget_test.dart --plain-name "day flow playback advances through route points"
flutter test
flutter build apk --debug
```

기기 검증:

```powershell
adb devices
adb -s R3CW706M57L install -r build\app\outputs\flutter-apk\app-debug.apk
adb -s R3CW706M57L shell am force-stop com.example.projectapp_1
adb -s R3CW706M57L shell am start -W -n com.example.projectapp_1/.MainActivity
```

확인 항목:

- 오늘 탭에서 `오늘의 흐름 보기`로 진입 가능.
- 상세 페이지 이동 경로에서 `그날의 흐름 보기`로 진입 가능.
- 새 페이지에서 지도 전체 경로가 보임.
- 재생 버튼으로 좌표가 순서대로 넘어감.
- 이전/다음 버튼이 동작함.
- 스크러버가 기록 구간 기준으로 조작됨.
- 재생 중 지도 이동/확대가 가능하고, 앱이 카메라를 강제로 움직이지 않음.

## 리스크와 대응

- 지도와 타이머가 같이 움직이면 rebuild 비용이 커질 수 있다.
  - 대응: 선택 상태만 `setState`, 지도 tile/layer는 가능한 한 단순하게 유지한다.
- GPS 튐이 있으면 재생 경로가 지저분할 수 있다.
  - 대응: raw points가 아니라 `DayRouteSnapshot.points`만 사용한다.
- route point가 너무 적은 날에 UI가 어색할 수 있다.
  - 대응: 0개/1개/2개 이상 상태를 분리한다.
- 타이머 누수 위험이 있다.
  - 대응: `dispose`에서 반드시 timer cancel.
- 오늘 날짜에서 end가 현재 시간인데 마지막 기록이 오래전이면 progress 오른쪽 끝에 빈 구간이 생긴다.
  - 의도된 동작이다. 오늘은 현재 시간 기준으로 들어가되, 실제 선택 좌표는 가장 가까운 마지막 기록으로 스냅한다.

## 구현 순서

1. `day_time_selection.dart`에 기록 구간 기반 유틸 추가 및 테스트.
2. `DayFlowPlaybackScreen` 기본 scaffold, 데이터 로딩, 빈 상태 구현.
3. 지도/경로/선택 마커 구현.
4. 하단 플레이어 패널과 스크러버 구현.
5. 이전/다음/재생 타이머 구현.
6. 오늘 탭 진입 연결 및 문구 추가.
7. 상세/돌아보기 상세 진입 연결 및 문구 추가.
8. 전체 테스트와 Android debug 빌드.
9. 테스트 기기 설치 후 실제 조작 확인.

## 다음 세션 시작 지점

다음 세션에서 바로 시작한다면 아래 순서로 진행한다.

1. 이 문서 읽기: `.docs/plans/2026-04-30-day-flow-playback.md`
2. 현재 관련 파일 확인:
   - `lib/features/timeline/day_time_selection.dart`
   - `lib/features/timeline/day_route_models.dart`
   - `lib/features/timeline/day_detail_screen.dart`
   - `lib/features/home/home_screen.dart`
   - `lib/app/app.dart`
3. 먼저 `day_time_selection.dart`의 기록 구간 유틸부터 구현한다.
4. 그 다음 `day_flow_playback_screen.dart`를 추가한다.
