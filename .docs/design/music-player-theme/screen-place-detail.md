# 장소 상세 화면 (Place Detail) — 신규

**레퍼런스:** `19f-place-detail.html`
**Flutter 파일:** `lib/features/places/place_detail_screen.dart` (신규 생성)
**데이터 소스:** `PlaceClusterRepository`, `DayTimelineRepository`

---

## 진입점

`PlacesScreen` 아이템 탭:
```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => PlaceDetailScreen(placeId: place.id),
));
```

---

## 화면 구조

```
CustomScrollView {
  SliverAppBar(expandedHeight:220, pinned:true) {
    → HeroSection
    → 핀 상태: 배경 mpBg, 장소명 페이드인
  }
  SliverToBoxAdapter {
    ActionRow
    StatStrip (3칸)
    SectionHeader("이번 달 방문 패턴")
    MonthlyHeatmap
    SectionHeader("요일별 평균 체류 시간")
    WeekdayBarChart
    SectionHeader("최근 방문")
    RecentVisitList
    SizedBox(height:24)
  }
}
```

---

## 섹션별 상세

### HeroSection (SliverAppBar)

expandedHeight: 220dp. 장소 위치를 FlutterMap으로 표시.

```dart
FlexibleSpaceBar(
  background: Stack {
    // 지도 (장소 마커 중심, 비활성 인터랙션)
    FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(place.latitude, place.longitude),
        initialZoom: 15,
        interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
      ),
      children: [
        TileLayer(urlTemplate: '...'),   // 타일 URL: 추후 결정
        MarkerLayer(markers: [
          Marker(
            point: LatLng(place.latitude, place.longitude),
            child: RouteVisitDot(),
          ),
        ]),
      ],
    ),

    // 하단 페이드
    Positioned(bottom:0, child: GradientFade(80dp, mpBg)),

    // 이름 + 주소 (하단 좌측)
    Positioned(bottom:16, left:24) {
      Text(placeName, 28sp, 800, white),
      Text(address, 13sp, muted),
    }
  }
)
```

**투명 AppBar 오버레이 (항상 표시):**
```dart
Positioned(top: MediaQuery.padding.top + 8) {
  Row(mainAxisAlignment: spaceBetween, padding: horizontal:20) {
    CircleBtn(size:34, bg: black50, child: Icon(arrow_back, white))
    Icon(more_vert, white)
  }
}
```

---

### ActionRow

```dart
Row(padding: horizontal:24, top:16, mainAxisAlignment: end) {
  CircleIconBtn(edit, 36)   // 장소 이름/이모지 편집
}
```

**편집 버튼 동작:** 장소 이름·이모지 수정 다이얼로그 (기존 기능 재활용).

---

### StatStrip (3칸)

```dart
Row {
  StatCell("$visitCount회", "방문"),
  VerticalDivider(),
  StatCell("${avgHours}h", "평균 체류"),
  VerticalDivider(),
  StatCell("${thisMonthCount}일", "이번 달"),
}
```

---

### MonthlyHeatmap

이번 달 일자별 방문 여부/횟수를 히트맵으로 표시.

```dart
Container(
  margin: EdgeInsets.symmetric(horizontal:24),
  decoration: BoxDecoration(color: mpSurface, borderRadius:12),
  padding: EdgeInsets.all(14),
  child: Column {
    Row(mainAxisAlignment: spaceBetween) {
      Text("$year년 $month월", 13sp, 600, white),
      Row { IconBtn(arrow_left), IconBtn(arrow_right) }
    },
    
    // 요일 헤더
    Row(mainAxisAlignment: spaceAround) {
      for (d in ["일","월","화","수","목","금","토"])
        Text(d, 9sp, muted, width:24)
    },
    
    // 날짜 그리드
    GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      children: calendarCells.map((cell) =>
        HeatmapCell(
          day: cell.day,
          level: cell.visitCount,   // 0=없음, 1=낮음, 2=보통, 3=높음
          isToday: cell.isToday,
          accentColor: place.accentColor,
        )
      )
    )
  }
)
```

**HeatmapCell 색상:**
```dart
Color cellColor(int level, Color accent) => switch(level) {
  0 => mpSurface2,          // 방문 없음 (#1A1A1A)
  1 => accent.withOpacity(0.25),
  2 => accent.withOpacity(0.55),
  3 => accent.withOpacity(0.85),
  _ => accent,
};
```

`isToday`: 추가 테두리 `Border.all(color: white.withOpacity(0.4), width:1)`

---

### WeekdayBarChart

요일별 평균 체류 시간 수평 막대 차트.

```dart
Container(
  margin: EdgeInsets.symmetric(horizontal:24),
  decoration: BoxDecoration(color: mpSurface, borderRadius:12),
  padding: EdgeInsets.all(14),
  child: Column {
    Text("주간 패턴", 13sp, 600, white),
    SizedBox(12),
    for (day in ["월","화","수","목","금","토","일"])
      Row {
        Text(day, 11sp, muted, width:24),
        Expanded(
          child: Stack {
            Container(height:8, borderRadius:4, color: mpSurface2),
            FractionallySizedBox(
              widthFactor: avgHoursForDay / maxAvgHours,
              child: Container(height:8, borderRadius:4, color: place.accentColor),
            )
          }
        ),
        Text(avgHoursForDay > 0 ? "${avgHoursForDay}h" : "—",
          11sp, muted, width:30, textAlign:right),
      }
  }
)
```

---

### RecentVisitList

최근 5개 방문 기록 (더보기 버튼 있음).

```dart
Column {
  for ((i, visit) in recentVisits.take(5).enumerated)
    RecentVisitRow(
      num: i + 1,
      dateStr: formatDateRelative(visit.date),  // "오늘", "3일 전", "4월 25일"
      timeRange: "${formatTime(visit.start)} — ${formatTime(visit.end)}",
      durationStr: visit.durationStr,
      tag: visit.tag,    // "진행 중" / "야근" / null
      accentColor: place.accentColor,
    )
  if (recentVisits.length > 5)
    TextButton("전체 방문 기록 보기 →", color: muted)
}
```

**RecentVisitRow:**
```
Row(padding: vertical:10, horizontal:24) {
  Text(num, 13sp, muted, width:24)
  Column(flex:1) {
    Text(dateStr, 14sp, 600, white)
    Text(timeRange, 12sp, muted)
  }
  Column(crossAxisAlignment: end) {
    Text(durationStr, 13sp, tag=="진행 중" ? accentColor : muted)
    if (tag != null)
      Badge(tag, bg: accentColor.withOpacity(0.12), color: accentColor)
  }
}
```

---

## 상태 관리

```dart
class PlaceDetailState {
  String placeId;
  PlaceSummary place;
  List<CalendarCell> calendarCells;
  Map<Weekday, double> weekdayAvgHours;  // 요일별 평균 체류
  List<PlaceVisit> recentVisits;
  int viewingMonth;   // 히트맵 현재 보는 월 (← → 버튼)
  bool isFavorite;
}
```

