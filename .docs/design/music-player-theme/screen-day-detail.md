# 하루 상세 화면 (Day Detail)

**레퍼런스:** `19e-day-detail.html`
**Flutter 파일:** `lib/features/timeline/day_detail_screen.dart`
**데이터 소스:** `DayTimelineRepository`, `DayRouteRepository`, `InsightGenerationService`

---

## 진입점

`HistoryScreen`의 아이템 탭 → `Navigator.push`:
```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => DayDetailScreen(date: selectedDate),
));
```

---

## 화면 구조

```
CustomScrollView {
  SliverAppBar(expandedHeight:200, floating:false, pinned:true) {
    → 평상시: HeroArtArea
    → 스크롤 시: 앱바 배경 mpBg, 제목 페이드인
  }
  SliverToBoxAdapter {
    DayTitleSection
    CheerMessageRow
    StatStrip (4칸)
    TimelineBarSection
    SectionHeader("방문 기록")
    TrackList
    InsightCard
    SizedBox(height:24)
  }
}
```

---

## 섹션별 상세

### SliverAppBar / HeroArtArea

확장 높이 200dp. 핀고정.

오늘 탭의 AlbumArtSection과 동일한 방식으로 FlutterMap 지도 표시.

```dart
FlexibleSpaceBar(
  background: Stack {
    // 지도 (비활성 인터랙션)
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
          Marker(point: LatLng(v.latitude, v.longitude),
            child: RouteVisitDot())
        ).toList()),
      ],
    ),

    // 하단 페이드 아웃
    Positioned(bottom:0, child: GradientFade(height:80, color: mpBg)),

    // 날짜 + 거리 배지 (하단 좌우)
    Positioned(bottom:14, left:16) {
      Text("APR $day", 28sp, 800, white),
      Text(dayOfWeekStr, 12sp, muted),
    },
    Positioned(bottom:18, right:16) {
      Badge("$km km"),
    }
  }
)
```

**데이터:**
```dart
final snapshot = await dayRouteRepository.getRouteForDate(date);
```

**빈 상태 (경로 없음):** 단색 배경 + 날짜 텍스트만 표시.

---

### DayTitleSection

```dart
Padding(horizontal:24, top:16) {
  Text(dateStr, 22sp, 700, white),   // 예: "4월 28일 월요일"
  Text(subtitleStr, 14sp, muted),    // "집 · 회사 · 카페 · 4곳 방문"
}
```

**dateStr 포맷:** `"${month}월 ${day}일 ${weekdayStr}"`  
weekdayStr: 월/화/수/목/금/토/일

---

### CheerMessageRow

오늘 탭의 CheerButton 말풍선과 동일한 문구 목록에서 해당 날짜 기준으로 하나를 고정 표시.

```dart
Padding(horizontal:24, top:14) {
  Text(cheerMessage, 14sp, mpAccent, fontStyle: italic),
}
```

**문구 선택:** `date.millisecondsSinceEpoch % _cheerMessages.length` — 날짜마다 고정된 문구.

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

---

### StatStrip

3칸: **걸음** / **장소** / **기록 시간**

```dart
Container(
  margin: EdgeInsets.symmetric(horizontal:24, vertical:16),
  decoration: BoxDecoration(color: mpSurface, borderRadius:12),
  child: Row {
    StatCell("$steps", "걸음"),
    VerticalDivider(color: mpSurface2),
    StatCell("$placeCount", "장소"),
    VerticalDivider(color: mpSurface2),
    StatCell("${hours}h ${mins}m", "기록"),
  }
)
```

---

### TimelineBarSection

24시간을 한 줄 막대로 시각화. 장소별 색상 세그먼트.

```dart
Container(
  margin: EdgeInsets.symmetric(horizontal:24),
  decoration: BoxDecoration(color: mpSurface, borderRadius:12),
  padding: EdgeInsets.all(14),
  child: Column {
    Text("0시 ——————————————————— 24시", 12sp, muted),
    SizedBox(height:10),
    
    // 세그먼트 바
    Stack(children: [
      Container(height:12, borderRadius:6, color: mpSurface2),
      for (segment in timelineSegments)
        FractionBar(
          start: segment.startMinute / 1440,
          end: segment.endMinute / 1440,
          color: segment.color,
          height: 12,
          borderRadius: 0,
        ),
    ]),
    
    // 시간 레이블
    Row(mainAxisAlignment: spaceBetween) {
      Text("0", 9sp, muted),
      Text("6", 9sp, muted),
      Text("12", 9sp, muted),
      Text("18", 9sp, muted),
      Text("24", 9sp, muted),
    },
    
    // 범례
    Wrap(spacing:12, runSpacing:4) {
      for (place in uniquePlaces)
        LegendItem(color: place.color, label: place.name)
    }
  }
)
```

**세그먼트 색상 매핑:**
- 집: `mpAccent` (#1DB954)
- 회사: `#4A8AFF`
- 카페: `#FF8A4A`
- 마트: `#FFCA4A`
- 이동(기타): `#555555`
- 새 장소: id hash로 결정

---

### TrackList (방문 기록)

방문 시간순 리스트.

```dart
Column {
  for ((index, visit) in visits.enumerated) {
    TrackListItem(
      num: index + 1,
      emoji: visit.place.emoji,
      isOngoing: visit.isOngoing,
      name: visit.place.name,
      timeRange: "${formatTime(visit.start)} — ${visit.end != null ? formatTime(visit.end!) : '진행 중'}",
      durationStr: visit.durationStr,
      waveData: visit.activityWave ?? generateDefaultWave(visit.durationMinutes),
      color: visit.place.accentColor,
    )
    if (index < visits.length - 1)
      Divider(indent:24, color: mpBorder, height:1)
  }
}
```

**TrackListItem 레이아웃:** (이모지/앨범아트 카드 없음)

```
Row(padding: vertical:10, horizontal:24) {
  Text(num, 13sp, muted, width:32)
  
  Column(flex:1) {
    Text(name, 14sp, 600, isOngoing ? mpAccent : white)
    Text(timeRange, 12sp, isOngoing ? mpAccent : muted)
    MiniWaveform(data: waveData, playedColor: color, height:18)
  }
  
  Text(durationStr, 13sp, isOngoing ? mpAccent : muted, 700)
}
```

---

### InsightCard

```dart
Container(
  margin: EdgeInsets.fromLTRB(24, 8, 24, 0),
  decoration: BoxDecoration(
    color: mpSurface,
    borderRadius: 14,
    border: Border(left: BorderSide(color: mpAccent, width:3)),
  ),
  padding: EdgeInsets.all(16),
  child: Column(crossAxisAlignment: start) {
    Text("💡 오늘의 인사이트", 10sp, 700, mpAccent, letterSpacing:1.5),
    SizedBox(8),
    Text(insightText, 14sp, color: Color(0xFFCCCCCC), height:1.6),
  }
)
```

`insightText`: `InsightGenerationService`가 생성한 텍스트. 없으면 기본 템플릿.

---

## 상태 관리

```dart
class DayDetailState {
  DateTime date;
  String dayTitle;
  List<PlaceVisit> visits;
  List<TimelineSegment> timelineSegments;
  DayStats stats;       // steps, places, recordedHours
  String insightText;
}
```
