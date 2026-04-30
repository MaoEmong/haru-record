# 하루 상세 페이지 변경 플랜

Status: APPROVED_FOR_INLINE_EXECUTION
Date: 2026-04-29
Skill: office-hours
Target: `lib/features/timeline/day_detail_screen.dart`
Reference:
- `.docs/design/music-player-theme/screen-day-detail.md`
- `.docs/design/music-player-theme/html/19e-day-detail.html`

## Product Read

하루 상세 페이지의 일은 "지도 화면"이 아니라 "하루를 다시 듣는 화면"이다. 사용자는 여기서 내가 어디를 갔는지, 어느 장소가 하루의 중심이었는지, 어떤 흐름으로 하루가 흘렀는지를 빠르게 읽어야 한다.

현재 화면은 기능은 있으나 정보가 카드 단위로 끊겨 보인다. 음악 플레이어 테마의 오늘 탭과 이어지는 감각도 약하다. 이전 시도처럼 큰 커스텀 페인터와 새 구조를 한 번에 넣으면 초기 렌더링과 전환 성능이 다시 흔들릴 가능성이 높다.

## Premise Challenge

1. 원본 HTML을 그대로 옮기면 안 된다.
   HTML은 정적인 데모다. 앱은 실제 FlutterMap, FutureBuilder, 위치 후처리, 방문 저장 액션이 있다. 큰 히어로 지도와 여러 시각 효과를 한 번에 넣으면 사용자는 예쁜 화면보다 버벅임을 먼저 본다.

2. "하루 상세"에 지도 인터랙션을 과하게 넣으면 안 된다.
   사용자가 상세에서 보고 싶은 것은 핀을 조작하는 행위가 아니라 하루의 흐름이다. 지도는 커버와 이동경로 확인용으로 충분하다.

3. "걸음/칼로리" 같은 없는 데이터를 억지로 만들면 안 된다.
   현재 앱은 위치 기반이다. 그래서 StatStrip은 방문, 이동거리, 기록 시간 중심으로 가야 한다.

4. 기존 방문 저장 플로우는 유지해야 한다.
   장소 흐름에서 머문 곳을 저장하는 기능은 최근에 검증한 핵심 흐름이다. 디자인 변경 때문에 이 기능이 깨지면 안 된다.

## Direction

HTML의 분위기는 가져오되, 구현은 단계적으로 제한한다.

1. `CustomScrollView`와 고정형 상단 커버로 바꾼다.
   상단은 200dp 정도의 히어로 영역으로 만들고, 기존 `_DayRouteMap` 또는 가벼운 플레이스홀더를 재사용한다. 새 커스텀 파형/패턴은 넣지 않는다.

2. 하루 제목과 짧은 응원 문구를 히어로 아래에 둔다.
   문구는 오늘 탭의 톤과 맞춘다. 과한 영어 라벨 대신 한국어 중심으로 간다.

3. 요약은 3칸 StatStrip으로 바꾼다.
   방문, 이동, 기록 시간을 보여준다. 움직임 시간은 제거한 기존 결정과 충돌하지 않도록 "기록 시간"은 타임라인에 기록된 체류 시간 합으로만 계산한다.

4. 24시간 타임라인 바를 추가한다.
   위치 흐름을 한 줄로 읽게 해주는 핵심 요소다. 빈 데이터일 때는 "기록이 쌓이면 하루 흐름이 표시돼요"로 처리한다.

5. 장소 흐름 리스트는 TrackList처럼 다듬는다.
   번호, 장소명, 시간, 미니 바/상태, 저장 액션을 한 줄 안에 정리한다. 기존 저장 다이얼로그와 새로고침은 유지한다.

6. 인사이트 카드는 마지막에 둔다.
   `widget.body`가 있으면 표시하고, 없으면 조용한 기본 문구를 쓴다. "인사이트"라는 단어는 유지 여부를 코드 단계에서 화면 톤에 맞춰 조정한다.

## Implementation Plan

1. 안전한 리팩토링 경계 설정
   - `day_detail_screen.dart`만 수정한다.
   - 데이터 repository, 후처리, DB schema는 건드리지 않는다.
   - 기존 widget test의 "day detail" 흐름이 통과해야 한다.

2. 레이아웃 골격 변경
   - `Scaffold + AppBar + ListView`를 `Scaffold + CustomScrollView`로 변경한다.
   - `SliverAppBar`에는 뒤로가기, 제목, 히어로 영역을 둔다.
   - 히어로는 성능을 위해 기존 지도 렌더 지연 구조를 재사용한다.

3. 요약/타임라인 컴포넌트 추가
   - `_SummaryCard`를 음악 플레이어 톤의 `_StatStripCard`로 대체한다.
   - `_TimelineBarCard`를 추가한다.
   - 새 위젯은 계산 로직을 작게 유지한다.

4. 장소 흐름 리스트 정리
   - `_RouteSummaryCard` 제목을 "방문 기록"으로 변경한다.
   - `_TimelineDetailRow`를 track item 형태로 정리한다.
   - `canSaveAsPlace` 액션과 key는 유지한다.

5. 빈 상태와 성능 방어
   - FutureBuilder를 하나의 큰 로딩으로 묶지 않는다.
   - 지도는 기존 `_DeferredRouteMapRender`를 유지한다.
   - 데이터가 없을 때도 화면 뼈대가 먼저 보이게 한다.

6. 검증
   - `dart format lib/features/timeline/day_detail_screen.dart`
   - `flutter analyze`
   - `flutter test test/widget_test.dart`

## Acceptance Criteria

- 하루 상세 진입 시 검은 빈 화면이나 긴 멈춤이 없어야 한다.
- 화면 상단이 오늘 탭의 음악 플레이어 테마와 이어져 보여야 한다.
- 방문/이동/기록 시간이 한눈에 보여야 한다.
- 24시간 흐름이 실제 timeline 데이터를 기반으로 표시되어야 한다.
- 장소 흐름에서 저장 가능한 머문 곳은 계속 저장할 수 있어야 한다.
- 기존 테스트가 통과해야 한다.

## Deferred

- 비슷한 하루 섹션은 이번 범위에서 제외한다.
- 걸음/칼로리 표시는 실제 데이터 소스가 생기기 전까지 제외한다.
- 히어로 지도에 복잡한 커스텀 페인터나 새 애니메이션은 넣지 않는다.
