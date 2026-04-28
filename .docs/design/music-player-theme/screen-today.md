# 오늘 화면 (Today / Now Playing)

**레퍼런스:** `19a-today.html`
**Flutter 파일:** `lib/features/home/home_screen.dart`
**데이터 소스:** `DayTimelineRepository`, `LocationTrackingService`, `InsightGenerationService`

---

## 화면 구조 (위→아래)

```
StatusBar (시스템)
NavBar
└── 중앙 제목: "오늘의 하루" (14sp, mpTextSub)
└── 우측: ••• (더보기)

Scroll (SingleChildScrollView)
├── AlbumArtSection
├── TrackInfoRow
├── StatsChipRow
├── WaveformSection
├── ProgressBarSection
├── ControlsRow
├── Divider
├── CurrentLocationCard
└── TodayVisitList

BottomNavigationBar (공통)
```

---

## 섹션별 상세

### AlbumArtSection

오늘 이동 경로를 지도로 표시하는 정사각형 카드. 이모지 없음.

- 컨테이너: `Padding(horizontal:36)`, 가로=전체 너비−72, 1:1 비율
- 코너: `ClipRRect(borderRadius:12)`
- 지도: `flutter_map`의 `FlutterMap` (이미 `pubspec.yaml`에 설치됨)
- 캐싱: `CachedMapSnapshot` 래퍼로 감싸 렌더링 후 PNG 캐시
- 지도 인터랙션: 비활성 (`InteractiveFlag.none`)
- 지도 bounds: 오늘 경로 전체가 들어오도록 `fitBounds` 자동 계산
- 타일 스타일 및 색상: **추후 결정**

**레이어 구성:**
```dart
FlutterMap(
  options: MapOptions(
    initialCameraFit: CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(routePoints),
      padding: EdgeInsets.all(32),
    ),
    interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
  ),
  children: [
    TileLayer(urlTemplate: '...'),   // 타일 URL: 추후 결정
    PolylineLayer(polylines: [
      Polyline(
        points: snapshot.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
        strokeWidth: 2.5,
        color: /* 추후 결정 */,
      ),
    ]),
    MarkerLayer(markers: snapshot.visits.map((v) =>
      Marker(
        point: LatLng(v.latitude, v.longitude),
        child: RouteVisitDot(/* 색상 추후 결정 */),
      )
    ).toList()),
  ],
)
```

**기록 중 badge** (지도 우상단 Positioned 오버레이):
- 내부: 애니메이션 dot (1.4s pulse) + "기록 중" 텍스트
- 기록 중이 아닐 때: 숨김

**데이터:**
```dart
final snapshot = await dayRouteRepository.getRouteForDate(today);
// snapshot.points → Polyline 경로
// snapshot.visits → 방문 장소 마커
final isRecording = locationTrackingService.isTracking;
```

**빈 상태 (오늘 경로 없음):**
- 지도 대신 단색 배경 + "아직 기록이 없어요" 텍스트
- 색상: 추후 결정

---

### TrackInfoRow

```
Row(
  mainAxisAlignment: spaceBetween,
  children: [
    Column(
      crossAxisAlignment: start,
      children: [
        Text("오늘의 하루", 22sp, 700, mpText),   // 고정 문구
        Text("$distanceKm km · $placeCount곳 방문", 13sp, mpTextSub),
      ]
    ),
    CheerButton(),   // 응원 말풍선 버튼 (즐겨찾기 아님)
  ]
)
```

#### CheerButton 동작 명세

아이콘을 탭하면 아이콘 바로 위에 말풍선이 나타난다.

**말풍선 내용:** 시간대별 응원 문구 목록에서 랜덤 선택
```dart
const _cheerMessages = [
  '오늘 하루도 열심히! 💪',
  '잘 하고 있어요 👏',
  '오늘도 수고했어요 ✨',
  '기록이 쌓이고 있어요 📈',
  '멋진 하루예요 🌟',
  '오늘도 파이팅! 🔥',
];
```

**말풍선 UI:**
```
Stack {
  // 말풍선 본체
  Container(
    padding: EdgeInsets.symmetric(horizontal:14, vertical:10),
    decoration: BoxDecoration(
      color: mpSurface,
      borderRadius: 12,
      boxShadow: [...],
    ),
    child: Text(message, 13sp, white),
  ),
  // 꼬리 (삼각형, 말풍선 하단 우측 정렬)
  Positioned(bottom:-6, right:12,
    child: Triangle(color: mpSurface, size:8),
  ),
}
```

**말풍선 위치:** `Stack` + `Positioned`로 아이콘 위에 absolute 배치.  
`OverlayEntry` 또는 같은 Row 내 `Column`으로 처리.

**닫힘 조건:**
1. 말풍선 영역을 다시 탭
2. 표시 후 3초 경과 (`Timer(Duration(seconds:3), _dismiss)`)

**상태:**
```dart
bool _bubbleVisible = false;
String _currentMessage = '';
Timer? _autoHideTimer;

void _onCheerTap() {
  if (_bubbleVisible) {
    _dismiss();
    return;
  }
  _currentMessage = _cheerMessages[Random().nextInt(_cheerMessages.length)];
  _autoHideTimer?.cancel();
  _autoHideTimer = Timer(const Duration(seconds: 3), _dismiss);
  setState(() => _bubbleVisible = true);
}

void _dismiss() {
  _autoHideTimer?.cancel();
  setState(() => _bubbleVisible = false);
}
```

**데이터:**
```dart
final distanceKm = visits.totalDistanceKm.toStringAsFixed(1);
final placeCount = visits.distinctPlaces.length;
```

---

### StatsChipRow

가로 스크롤 `Row`, 칩 4개. 색상은 추후 결정.

| 순서 | 아이콘 | 값 | 레이블 | 데이터 소스 |
|------|--------|-----|--------|------------|
| 1 | 📅 | 오늘 날짜 (예: "4월 28일") | — (날짜 자체가 레이블) | `DateTime.now()` |
| 2 | 👟 | 걸음 수 | 걸음 | `health` 패키지 |
| 3 | 📍 | 방문 장소 수 | 장소 | `DayTimelineRepository` |
| 4 | ⏱ | 기록 경과 시간 (H시간 M분) | 경과 | `LocationTrackingService` |

**만보기 구현 (health 패키지):**
```yaml
# pubspec.yaml 추가
health: ^10.x.x
```

```dart
// 권한 요청 (Android: activity_recognition, iOS: HKQuantityTypeIdentifierStepCount)
final health = HealthFactory();
await health.requestAuthorization([HealthDataType.STEPS]);

// 오늘 걸음 수 조회
final steps = await health.getTotalStepsInInterval(
  DateTime.now().copyWith(hour:0, minute:0, second:0),
  DateTime.now(),
);
```

권한 없거나 데이터 없을 때: `"—"` 표시 (에러 없이 graceful fallback).

**칩 위젯:**
```dart
Container(
  decoration: BoxDecoration(
    color: mpSurface,
    borderRadius: BorderRadius.circular(20),
  ),
  padding: EdgeInsets.symmetric(horizontal:14, vertical:7),
  child: Row(children: [icon, value(13sp,700,white), label(11sp,muted)])
)
```

날짜 칩(1번)은 값만 표시, 레이블 없음:
```dart
Column(children: [
  Text("4월", 10sp, muted),
  Text("28", 18sp, 700, white),
])
```

---

### WaveformSection

유지. 지도와 별개로 시간대별 활동 밀도를 직관적으로 보여주는 역할.

- `WaveformVisualizer` 위젯 (공통 위젯 신규 생성)
- 높이: 48dp, 가로 패딩: 24dp
- 바 개수: ~54개 (화면 너비 ÷ 7dp)
- 애니메이션: 각 막대 scaleY 0.55↔1.0 루프 (offset 있어서 물결처럼)
- 색상: 추후 결정

**데이터 — 시간대별 이동 밀도:**
```dart
// 하루를 54구간으로 나눠 구간별 GPS 포인트 수를 정규화
List<double> buildWaveData(List<DayRoutePoint> points) {
  const buckets = 54;
  final counts = List<double>.filled(buckets, 0);
  for (final p in points) {
    final minuteOfDay = p.timestamp.hour * 60 + p.timestamp.minute;
    final idx = (minuteOfDay / 1440 * buckets).floor().clamp(0, buckets - 1);
    counts[idx]++;
  }
  final max = counts.reduce(math.max);
  if (max == 0) return List.filled(buckets, 0.1); // 데이터 없으면 낮은 기본값
  return counts.map((c) => 0.1 + 0.9 * (c / max)).toList(); // 0.1~1.0 정규화
}
```

현재 시각 기준:
- 좌측 (지난 구간): 밝은 색
- 우측 (남은 구간): 어두운 색
- 색상값: 추후 결정

---

### ProgressBarSection

읽기 전용. 인터랙션(탭·드래그) 없음. 노브는 비주얼 장식.

```dart
IgnorePointer(   // 터치 이벤트 전부 무시
  child: Column(children: [
    Stack(alignment: Alignment.centerLeft, children: [
      // 트랙
      Container(height:4, color: mpSurface2),
      // fill
      FractionallySizedBox(widthFactor: progress,
        child: Container(height:4, color: /* 추후 결정 */)),
      // 노브 (장식용)
      Positioned(
        left: progress * trackWidth - 6,
        child: Container(
          width:12, height:12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: /* 추후 결정 */,
          ),
        ),
      ),
    ]),
    SizedBox(height:6),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(currentTimeStr, fontSize:11, color: mpTextSub),  // 예: "09:41"
      Text("23:59",        fontSize:11, color: mpTextSub),
    ]),
  ]),
)
```

**progress** = `(currentHour * 60 + currentMinute) / 1439`

`Timer.periodic(Duration(seconds: 30))` 로 갱신.

---

### ControlsRow

5개 버튼 전부 유지. 각 버튼의 구체적 기능은 추후 결정.

```
Row(mainAxisAlignment: spaceEvenly) {
  IconButton("⇄", color: mpAccent)   // 기능 추후 결정
  IconButton("⏮", color: mpTextSub)  // 기능 추후 결정
  IconButton("⏸/▶", size:56, color: white)  // 기능 추후 결정
  IconButton("⏭", color: mpTextSub)  // 기능 추후 결정
  IconButton("↻", color: mpAccent)   // 기능 추후 결정
}
```

---

### CurrentLocationCard

현재 머물고 있는 장소 카드. 위치 이벤트 스트림에서 실시간 업데이트.

```
Container(
  decoration: BoxDecoration(
    color: mpSurface,
    border: Border.all(color: mpAccent.withOpacity(0.25)),
    borderRadius: 12,
  ),
  child: Row {
    CircleAvatar(48, bg: mpSurface2, child: emoji)
    Column {
      Text(placeName, 15sp, 700, white)
      Text("오전 9:30 도착", 12sp, muted)
    }
    Column(crossAxisAlignment: end) {
      Text(durationStr, 12sp, mpAccent, 700)
      LiveBarsWidget()   // 4개 짧은 막대 애니메이션
    }
  }
)
```

**LiveBarsWidget:** 높이 4–18dp 범위, 4개 막대, `AnimationController` 루프

**데이터:**
```dart
final current = locationTrackingService.currentPlace;  // PlaceLabel?
final arrivedAt = locationTrackingService.currentPlaceArrivedAt;
final duration = DateTime.now().difference(arrivedAt);
```

---

### TodayVisitList

오늘 방문한 장소 목록 (최대 5개, 나머지는 "N개 더보기").

```
Column {
  SectionHeader("오늘 방문한 곳")
  for (i, visit) in visits.enumerated {
    TrackListItem(
      num: i+1,
      emoji: visit.place.emoji,
      name: visit.place.name,
      timeRange: "${visit.start} — ${visit.end ?? '진행 중'}",
      duration: visit.duration,
      isCurrent: visit.isOngoing,
      miniWaveform: visit.activityWave,
    )
  }
}
```

확정된 방문 기록만 표시 (과거 + 진행 중). 패턴 기반 미래 예측은 표시하지 않음.

---

## 상태 관리

```dart
class TodayScreenState {
  DayTimeline? todayTimeline;
  PlaceVisit? currentVisit;
  bool isRecording;
  double timeProgress;   // 0.0~1.0
  List<double> waveData; // 길이 ~54
  int streakDays;
}
```

`Timer.periodic(Duration(seconds:30))` 로 `timeProgress` 업데이트.
LocationTrackingService 스트림 구독으로 `currentVisit` 실시간 업데이트.
