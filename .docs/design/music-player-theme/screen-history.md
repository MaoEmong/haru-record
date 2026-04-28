# 돌아보기 화면 (History / Queue)

**레퍼런스:** `19b-history.html`
**Flutter 파일:** `lib/features/history/history_screen.dart`
**데이터 소스:** `DayTimelineRepository`, `DayActivityPreviewRepository`

---

## 화면 구조

```
StatusBar
Padding(24) {
  Text("돌아보기", 28sp, 800, white)
  Text("N일의 하루들", 13sp, muted)
}
ListView (grouped)
BottomNavigationBar
```

---

## 섹션별 상세

### 헤더

```dart
Column(crossAxisAlignment: start) {
  Text("돌아보기", fontSize:28, fontWeight:800, color:white),
  Text("$totalDays일의 하루들", fontSize:13, color:muted),
}
```

`totalDays`: DB에 기록된 유니크 날짜 수.

---

### ListView

`ListView.builder`로 구현. 날짜 내림차순, 그룹 헤더 없음.

---

### HistoryTrackItem (일반)

```
Row(padding: vertical 8, horizontal 24) {
  AlbumArtCard(50×50, gradient, emoji)
  Column(flex:1) {
    Text(dayTitle, 14sp, 600, white)       // AI 생성 또는 "N월 N일"
    Text("N월 N일 · X.X km · N곳", 12sp, muted)
  }
  Row {
    Text("HH:MM", 12sp, muted)   // 총 기록 시간 (시:분)
    Icon(Icons.more_vert, muted)
  }
}
```

**dayTitle 규칙:**
- `InsightNarrator`에서 생성된 제목 있으면 사용
- 없으면: `"N월 N일"` + 주요 방문지 (예: "집 → 회사 → 카페")

**탭 동작:** `Navigator.push(DayDetailScreen(date: item.date))`

---

### HistoryTrackItem (오늘 — 재생 중)

일반 아이템과 동일하나:
- 제목·날짜 색상: `mpAccent`
- 오른쪽: 체류 시간 대신 `LiveBarsWidget` (3–4개 막대 애니메이션)
- 카드 배경 없음 (highlight 없음, 색상만 구분)

---

## 상태 관리

```dart
class HistoryScreenState {
  List<DayPreview> days;   // 날짜 내림차순
  bool isLoading;
}
```

```dart
class DayPreview {
  DateTime date;
  String title;
  double distanceKm;
  int placeCount;
  String emoji;       // 그날의 대표 이모지
  bool isFavorite;
  bool isToday;
}
```

**페이지네이션:** `ScrollController`로 하단 도달 시 이전 달 데이터 추가 로드.
