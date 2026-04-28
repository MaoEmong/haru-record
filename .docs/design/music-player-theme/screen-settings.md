# 설정 화면 (Settings)

**레퍼런스:** `19d-settings.html`
**Flutter 파일:** `lib/features/settings/settings_screen.dart`
**데이터 소스:** `SettingsRepository`, `DayTimelineRepository`, `PlaceClusterRepository`

> **방침:** 설정 항목은 기존 코드(`settings_screen.dart`)를 그대로 유지. 디자인(색상·레이아웃·컴포넌트)만 뮤직 플레이어 테마로 교체.

---

## 화면 구조

```
StatusBar
SingleChildScrollView {
  PageHeader ("설정")
  StatsCard
  TrustCard
  SectionHeader("기록") + SettingsGroup(기록)
  SectionHeader("알림") + SettingsGroup(알림)
  SectionHeader("데이터") + SettingsGroup(데이터)
}
BottomNavigationBar
```

---

## 섹션별 상세

### PageHeader

```dart
Padding(horizontal:24, top:20) {
  Text("설정", 28sp, 800, white),
  Text("기록 방식과 보관 기준을 조정해요.", 13sp, muted),
}
```

---

### StatsCard

기존 기록 통계 3칸 표시.

```dart
Container(
  margin: EdgeInsets.fromLTRB(24,12,24,0),
  decoration: BoxDecoration(color: mpSurface, borderRadius:16),
  padding: EdgeInsets.symmetric(vertical:16),
  child: Row(mainAxisAlignment: spaceAround) {
    StatCell("$streak일", "연속 기록"),
    VerticalDivider(color: mpBorder),
    StatCell("$totalKm km", "총 이동 거리"),
    VerticalDivider(color: mpBorder),
    StatCell("$totalPlaces곳", "머문 곳"),
  }
)
```

**데이터:**
```dart
final streak = await dayTimelineRepository.getCurrentStreak();
final totalKm = await dayTimelineRepository.getTotalDistanceKm();
final totalPlaces = await placeClusterRepository.getTotalUniquePlaces();
```

---

### TrustCard

기존 TrustCard 내용 유지, 디자인만 교체.

```dart
Container(
  margin: EdgeInsets.fromLTRB(24,12,24,0),
  decoration: BoxDecoration(
    color: mpSurface,
    borderRadius: 12,
    border: Border.all(color: mpAccent.withOpacity(0.2)),
  ),
  padding: EdgeInsets.all(16),
  child: Column(crossAxisAlignment: start) {
    Text("기록은 이 기기에만 저장돼요", 14sp, 700, white),
    SizedBox(6),
    Text("움직임이 있을 때 중심으로 살펴 배터리 사용을 줄여요", 13sp, muted),
  }
)
```

---

### SettingsGroup 공통 컨테이너

```dart
Container(
  margin: EdgeInsets.symmetric(horizontal:24),
  decoration: BoxDecoration(color: mpSurface, borderRadius:12),
  child: Column(children: rows),
)
```

각 행 사이: `Divider(height:1, color: mpBorder, indent:56)`

---

### SettingsGroup: 기록

기존 항목 유지:

| 설정 항목 | 타입 | 기존 동작 |
|-----------|------|-----------|
| 하루 기록 | Toggle | `LocationTrackingService.startTracking()` / `stopTracking()` |
| 움직임으로 볼 거리 | Chevron + 값 (m) | 숫자 입력 다이얼로그 → `minimumMovementMeters` |
| 머문 곳으로 볼 시간 | Chevron + 값 (분) | 숫자 입력 다이얼로그 → `minimumStayMinutes` |

```dart
SettingRow(
  icon: Icons.route_outlined, iconBg: Color(0xFF0D2A0D),
  label: "하루 기록",
  sub: settings.trackingEnabled ? "오늘의 흐름을 기록하고 있어요" : "쉬고 있어요",
  trailing: Switch(value: settings.trackingEnabled, onChanged: ...),
)
```

---

### SettingsGroup: 알림

기존 항목 유지:

| 설정 항목 | 타입 | 기존 동작 |
|-----------|------|-----------|
| 돌아보기 알림 | Toggle | `notificationService.scheduleDailyInsight()` / `cancelDailyInsight()` |
| 돌아보기 알림 시간 | Chevron + 값 | 시:분 입력 다이얼로그 → `notificationHour` / `notificationMinute` |

---

### SettingsGroup: 데이터

기존 항목 유지:

| 설정 항목 | 타입 | 기존 동작 |
|-----------|------|-----------|
| 자세한 위치 보관 기간 | Chevron + 값 (일) | 숫자 입력 → `rawPointRetentionDays` |
| 어제 돌아보기 만들기 | 액션 버튼 | `runDailyProcessingNow()` |
| 자세한 위치 기록 비우기 | 액션 버튼 (확인 다이얼로그) | `maintenanceService.deleteRawLocationPoints()` |
| 이 기기의 기록 모두 지우기 | 액션 버튼 (확인 다이얼로그) | `maintenanceService.deleteAllLocalData()` |

삭제 액션 행: `Text(label, color: Colors.red[400])`

---

## SettingRow 위젯 명세

재사용 컴포넌트 (기존 `_SettingsRow` 교체):

```dart
class SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final String? sub;
  final Widget? trailing;
  final VoidCallback? onTap;

  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal:16, vertical:14),
        children: [
          Container(
            width:36, height:36, borderRadius:10,
            color: iconBg,
            child: Icon(icon, color: mpAccent, size:18),
          ),
          SizedBox(14),
          Column(flex:1, crossAxisAlignment:start) {
            Text(label, 15sp, 700, white),
            if (sub != null) Text(sub!, 12sp, muted),
          },
          if (trailing != null) trailing!
          else Icon(Icons.chevron_right, muted),
        ],
      ),
    ),
  );
}
```
