# 머문 곳 화면 (Stayed Places / Library)

**레퍼런스:** `19c-places.html`
**Flutter 파일:** `lib/features/places/place_management_screen.dart`
**데이터 소스:** `PlaceClusterRepository`, `DayTimelineRepository`

---

## 화면 구조

```
StatusBar
Row(헤더: "머문 곳" + "방문 많은 순 ↓")
ListView {
  SectionHeader("자주 가는 곳")
  FeaturedPlaceCard             ← 방문 횟수 1위 장소
  SectionHeader("전체 장소")
  PlaceListItems...             ← 방문 많은 순 정렬
  SectionHeader("이름 없는 곳")
  UnnamedPlaceGridRow           ← 이름 미지정 감지 장소 2열 그리드
}
BottomNavigationBar
```

---

## 섹션별 상세

### 헤더

```dart
Row(mainAxisAlignment: spaceBetween) {
  Text("머문 곳", fontSize:28, fontWeight:800, color:white),
  Text("방문 많은 순 ↓", fontSize:12, fontWeight:600, color:muted),
}
```

"방문 많은 순 ↓" 탭 → 정렬 옵션 BottomSheet (방문 많은 순 / 최근 방문 / 체류 긴 순)

---

### FeaturedPlaceCard

방문 횟수 1위 장소를 크게 강조.

```dart
Container(
  margin: EdgeInsets.symmetric(horizontal:24),
  decoration: BoxDecoration(
    borderRadius: 16,
    border: Border.all(color: mpAccent.withOpacity(0.2)),
  ),
  child: Column {
    // 아트 영역 (120dp 높이)
    Container(
      height:120,
      decoration: BoxDecoration(gradient: placeGradient),
      child: Stack {
        Center(child: Text(emoji, fontSize:56)),
        Positioned(top:10, left:12,
          child: Badge("⭐ 1위", bg: mpAccent.withOpacity(0.9), textColor: black)),
      }
    ),
    // 정보 영역
    Padding(14) {
      Text(placeName, 20sp, 700, white),
      Text(address, 13sp, muted),
      Row(gap:20) {
        StatMini("$visits회", "방문"),
        StatMini("$avgHours시간", "평균 체류"),
        StatMini("$streak일 연속", "스트릭"),
      },
      LinearProgressIndicator(value: 1.0, color: mpAccent),  // 1위이므로 100%
    }
  }
)
```

---

### PlaceListItem

```dart
Row(padding: EdgeInsets.symmetric(horizontal:24, vertical:10)) {
  CircleAvatar(52,
    background: placeGradient,
    child: Text(emoji, fontSize:24)),
  
  Column(flex:1) {
    Text(name, 15sp, 600, white),
    Text("$district · 마지막 방문 $lastVisitStr", 12sp, muted),
    PlaceBadge(place),   // streak / 패턴 / 즐겨찾기 / 새로운 곳
  },
  
  Column(crossAxisAlignment: end) {
    Text("$pct%", 13sp, 700, mpAccent),
    Text("$visitCount회", 11sp, muted),
    MicroProgressBar(value: pct/100, color: mpAccent),
  }
}
```

**PlaceBadge 규칙:**
| 조건 | 배지 |
|------|------|
| 연속 방문 7일↑ | 🔥 N일 연속 |
| 주 N회 이상 정기 패턴 | 📅 주 N회 패턴 |
| 즐겨찾기 등록 | 💚 즐겨찾기 |
| 이번 달 첫 방문 | 🆕 이번 달 발견 |

**탭 동작:** `Navigator.push(PlaceDetailScreen(placeId: place.id))`

---

### UnnamedPlaceGridSection ("이름 없는 곳")

GPS 클러스터링으로 감지됐지만 아직 사용자가 이름을 지정하지 않은 장소. 2열 그리드.

탭 시 → 이름·이모지 지정 다이얼로그.

```dart
GridView.count(
  crossAxisCount: 2,
  padding: EdgeInsets.symmetric(horizontal:24),
  mainAxisSpacing: 8, crossAxisSpacing: 8,
  shrinkWrap: true,
  children: unnamedPlaces.map((p) =>
    PlaceGridCard(
      artHeight: 80,
      emoji: "📍",          // 이름 없으면 기본 핀 이모지
      name: p.district,     // 행정구만 표시 (예: "강남구 역삼동")
      sub: "${p.visitCount}회 머문 곳",
      isUnnamed: true,      // 점선 테두리 등 미지정 스타일
    )
  )
)
```

---

## 상태 관리

```dart
class PlacesScreenState {
  List<PlaceSummary> places;     // 방문 많은 순 정렬
  PlaceSummary? topPlace;        // 1위 장소
  List<UnnamedPlace> unnamedPlaces;  // 이름 미지정 감지 장소
  SortType sortType;
}
```

```dart
class PlaceSummary {
  String id;
  String name;
  String emoji;
  String district;        // 행정구
  int visitCount;
  double avgStayHours;
  DateTime lastVisited;
  int streakDays;
  bool isFavorite;
  bool isNewThisMonth;
  double visitPercent;    // 전체 기록일 대비 방문율
  Color accentColor;      // 장소별 고정 색 (id hash 기반)
}
```
