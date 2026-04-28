# 뮤직 플레이어 테마 — 디자인 개요

## 배경

선택된 레이아웃 방향: **19번 뮤직 플레이어** (Spotify Dark 스타일)

기존 앱은 earthy green 계열의 라이트 테마였으나, 사용자가 뮤직 플레이어 UI 패턴으로
리디자인하기로 결정. 일상 이동 기록이라는 컨텐츠를 "오늘 하루를 한 장의 앨범"으로
재해석한 메타포를 전면에 사용한다.

## 디자인 레퍼런스 HTML 파일

모든 레퍼런스 HTML 파일 위치:
`C:\Users\G\.gstack\projects\MaoEmong-codex_app_1\designs\layout-variants-20260428\`

| 파일 | 담당 화면 |
|------|-----------|
| `19a-today.html` | 오늘 (홈) |
| `19b-history.html` | 돌아보기 (기록 리스트) |
| `19c-places.html` | 방문한 곳 (장소 라이브러리) |
| `19d-settings.html` | 설정 |
| `19e-day-detail.html` | 하루 상세 |
| `19f-place-detail.html` | 장소 상세 |

브라우저에서 `19-pages-gallery.html`을 열면 6개 페이지를 나란히 비교할 수 있다.

---

## 색상 토큰

```dart
// app_theme.dart 에 추가할 새 토큰
static const Color mpBg         = Color(0xFF0D0D0D);  // 앱 배경
static const Color mpSurface    = Color(0xFF1A1A1A);  // 카드 배경
static const Color mpSurface2   = Color(0xFF242424);  // 중첩 카드
static const Color mpBorder     = Color(0xFF2A2A2A);  // 구분선
static const Color mpAccent     = Color(0xFF1DB954);  // Spotify 그린 (주 강조)
static const Color mpAccentDark = Color(0xFF158A3E);  // 눌렸을 때
static const Color mpText       = Color(0xFFFFFFFF);  // 주 텍스트
static const Color mpTextSub    = Color(0xFF888888);  // 보조 텍스트
static const Color mpTextMuted  = Color(0xFF555555);  // 비활성 텍스트
```

---

## 타이포그래피

| 용도 | 크기 | 굵기 | 색상 |
|------|------|------|------|
| 페이지 대제목 | 28sp | 800 | mpText |
| 카드 제목 | 20–22sp | 700 | mpText |
| 섹션 헤더 | 16sp | 700 | mpText |
| 리스트 아이템 제목 | 14–15sp | 600 | mpText |
| 보조 텍스트 | 12–13sp | 400 | mpTextSub |
| 레이블 (캡션) | 10–11sp | 700 | mpTextMuted, mpAccent |

---

## 공통 컴포넌트 패턴

### AlbumArtCard
- 정사각형 카드 (오늘 페이지: 전체 너비, 리스트: 50×50dp)
- 배경: `LinearGradient(135deg, #0A2A0A → #1A4A1A)` (장소마다 다른 색)
- 코너 반경: 리스트 8dp / 상세 16dp
- 이모지 + 날짜/이름 텍스트

### WaveformVisualizer
- 다수의 얇은 수직 막대 (너비 2–3dp, 간격 2dp, 코너 2dp)
- 재생된 구간: `mpText(white)`, 미재생 구간: `mpSurface2(#333)`
- 높이 배열은 하루 활동량/이동량 데이터에서 파생
- AnimationController로 scaleY 0.55↔1.0 루프

### ProgressBar (시간 진행)
- 높이 4dp, 배경 `mpSurface2`, fill `mpText`
- 진행 노브: 12dp 흰 원 (탭 가능)
- 양쪽 시간 레이블 (현재 시각 / 23:59)

### TrackListItem (방문 기록 행)
```
[순번] [AlbumArtCard 50×50] [제목 + 보조] [미니 파형] [체류 시간]
```
- 현재(진행 중) 아이템: 제목·시간 `mpAccent`, 카드 테두리 `mpAccent 25% opacity`
- 초록 dot indicator (카드 우하단 12dp 원)

### StatStrip (통계 4분할)
- `Row` 4개 셀, `Divider(vertical)` 구분
- 배경 `mpSurface`, 코너 12dp
- 상단: 값(16sp bold white), 하단: 레이블(10sp muted)

### SectionHeader
- `padding(left:24, top:20, bottom:10)`
- 16sp, 700, mpText

### FilterPill
- 비활성: bg `mpSurface`, text mpText
- 활성: bg mpText(white), text `mpBg(black)`
- 코너 20dp, 가로 스크롤 Row

### ToggleSwitch (설정)
- ON: bg `mpAccent`, 노브 white
- OFF: bg `#333`, 노브 `#888`

---

## 네비게이션 구조

```
MainShell (하단 TabBar 4탭)
├── Tab 0: TodayScreen          ← home_screen.dart 교체
├── Tab 1: HistoryScreen        ← history_screen.dart 교체
├── Tab 2: PlacesScreen         ← place_management_screen.dart 교체
└── Tab 3: SettingsScreen       ← settings_screen.dart 교체

DayDetailScreen                 ← day_detail_screen.dart 교체
  (HistoryScreen 아이템 탭 → push)

PlaceDetailScreen               ← 신규 파일
  (PlacesScreen 아이템 탭 → push)
```

### BottomNavigationBar 스펙
- 배경: `mpBg`
- 상단 구분선: `mpBorder`
- 높이: 72dp (하단 safe area 포함)
- 비활성 아이콘/레이블: `mpTextMuted`
- 활성 아이콘/레이블: `mpAccent`
- 아이콘: 22sp 이모지 또는 Icon 위젯

| 탭 | 아이콘 | 레이블 |
|----|--------|--------|
| 0 | ▶️ | 오늘 |
| 1 | 📋 | 기록 |
| 2 | 📍 | 장소 |
| 3 | ⚙️ | 설정 |

---

## 기존 코드 → 신규 매핑

| 기존 파일 | 역할 유지 | 변경 사항 |
|-----------|-----------|-----------|
| `app_theme.dart` | 색상/타이포 | 새 토큰 추가 |
| `home_screen.dart` | 오늘 홈 | UI 전면 교체 |
| `history_screen.dart` | 기록 목록 | UI 전면 교체 |
| `place_management_screen.dart` | 장소 목록 | UI 전면 교체 |
| `settings_screen.dart` | 설정 | UI 전면 교체 |
| `day_detail_screen.dart` | 하루 상세 | UI 전면 교체 |
| `day_timeline_repository.dart` | 데이터 유지 | 변경 없음 |
| `place_cluster_repository.dart` | 데이터 유지 | 변경 없음 |
| `insight_generation_service.dart` | 데이터 유지 | 변경 없음 |

**신규 파일:**
- `lib/features/places/place_detail_screen.dart`
- `lib/shared/widgets/waveform_visualizer.dart`
- `lib/shared/widgets/album_art_card.dart`

---

## 구현 권장 순서

1. `app_theme.dart` — 색상 토큰 추가
2. 공통 위젯 (`WaveformVisualizer`, `AlbumArtCard`, `TrackListItem`, `StatStrip`)
3. `TodayScreen` (가장 핵심, 임팩트 큼)
4. `HistoryScreen`
5. `PlacesScreen`
6. `DayDetailScreen`
7. `PlaceDetailScreen` (신규)
8. `SettingsScreen`
