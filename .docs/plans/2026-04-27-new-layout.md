# New Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current card-heavy UI with the "Ink Journal" layout — a diary-feel design with a large date hero, dark ink insight card, dot-line timeline, month-grouped history, place grid, and grouped settings sections.

**Architecture:** Each screen is a self-contained StatefulWidget that receives `AppDependencies` or `AppDatabase` directly; no state management library is used. Layout changes are purely cosmetic — data loading logic (FutureBuilder + snapshot pattern) stays intact. New private widget classes replace old ones inside the same files.

**Tech Stack:** Flutter (Material 3), Drift ORM, `AppColors`/`AppThemeDecorations` from `lib/app/app_theme.dart`, `KyoboHandwriting` font (already registered in `pubspec.yaml`).

**Reference design:** `.docs/layout-preview.html` — open in a browser to compare while working.

---

## File Map

| File | Action | What changes |
|---|---|---|
| `lib/features/home/home_screen.dart` | Modify | Remove `_StatusPanel`, `_TodayRecordPanel`; add `_DateHero`, `_StatChips`, `_DarkInsightCard`, `_DotTimeline`, `_QuickActionCard`; snapshot adds `todayDailySummary`, removes `todayPointCount` |
| `lib/app/app.dart` | Modify | `DailyPatternShell` adds persistent app header (app name + tracking badge) above tab content |
| `lib/features/history/history_screen.dart` | Modify | Group insights by month; replace `ListTile` with `_HistoryCard` (day number \| divider \| badge + title + meta) |
| `lib/features/places/place_management_screen.dart` | Modify | Replace `ListView` with featured full-width card + 2-column grid rows |
| `lib/features/settings/settings_screen.dart` | Modify | Add page title + status card; group rows into labelled sections (기록, 알림, 데이터); replace `SwitchListTile`/`_EditableSettingsValueTile` with unified `_SettingsRow` |

---

## Task 1 — HomeScreen: snapshot refactor (remove point count, add daily summary)

**Files:**
- Modify: `lib/features/home/home_screen.dart`

The snapshot currently stores `todayPointCount: int` which surfaces the "포인트" concept we're removing. Replace it with `todayDailySummary: DailySummary?` so stats chips can show `totalDistanceMeters`, `visitCount`, and `movingMinutes` from the existing DB table.

- [ ] **Step 1: Update `_HomeSnapshot` class** (bottom of the file, ~line 406)

Replace:
```dart
class _HomeSnapshot {
  const _HomeSnapshot({
    required this.settings,
    required this.isTracking,
    required this.latestInsight,
    required this.todayPointCount,
    required this.timeline,
  });

  final AppSettings settings;
  final bool isTracking;
  final Insight? latestInsight;
  final int todayPointCount;
  final List<DayTimelineItem> timeline;
}
```
With:
```dart
class _HomeSnapshot {
  const _HomeSnapshot({
    required this.settings,
    required this.isTracking,
    required this.latestInsight,
    required this.todayDailySummary,
    required this.timeline,
  });

  final AppSettings settings;
  final bool isTracking;
  final Insight? latestInsight;
  final DailySummary? todayDailySummary;
  final List<DayTimelineItem> timeline;
}
```

- [ ] **Step 2: Replace `_loadTodayPointCount` with `_loadTodayDailySummary`**

Remove the entire `_loadTodayPointCount` method (~line 67–80) and add:
```dart
Future<DailySummary?> _loadTodayDailySummary() async {
  final now = DateTime.now();
  final dateStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final rows = await (widget.dependencies.database
          .select(widget.dependencies.database.dailySummaries)
        ..where((s) => s.date.equals(dateStr)))
      .get();
  return rows.firstOrNull;
}
```

- [ ] **Step 3: Update `_load()` to call the new method** (~line 47)

Replace:
```dart
    final todayPointCount = await _loadTodayPointCount();
```
With:
```dart
    final todayDailySummary = await _loadTodayDailySummary();
```

And update the `_HomeSnapshot(...)` constructor call in `_load()`:
```dart
    return _HomeSnapshot(
      settings: settings,
      isTracking: isTracking,
      latestInsight: insights.firstOrNull,
      todayDailySummary: todayDailySummary,
      timeline: timeline,
    );
```

- [ ] **Step 4: Verify the app compiles**

```bash
cd d:/my_project/flutter_tab/codex_app_1
flutter analyze lib/features/home/home_screen.dart
```

Expected: no errors. (The `build` method still references `_StatusPanel`, `_TodayRecordPanel` etc — those reference the snapshot; they'll be replaced in Task 2 but won't cause compile errors yet because the old fields are just gone — fix any reference to `todayPointCount` that remains.)

- [ ] **Step 5: Run existing home-related tests**

```bash
flutter test test/app/app_dependencies_test.dart
```

Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/home_screen.dart
git commit -m "refactor(home): replace todayPointCount with todayDailySummary in snapshot"
```

---

## Task 2 — HomeScreen: date hero + stats chips

**Files:**
- Modify: `lib/features/home/home_screen.dart`

Replace `_StatusPanel` and `_TodayRecordPanel` with a date hero and a row of stats chips. The date hero shows the current date large (diary-feel). Stats chips show distance, visit count, and moving minutes from `todayDailySummary`.

- [ ] **Step 1: Add `_DateHero` widget** (add above `_HomeSnapshot` class, at the bottom of the file)

```dart
class _DateHero extends StatelessWidget {
  const _DateHero({required this.isTracking});

  final bool isTracking;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[now.weekday - 1];
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${now.year}년 · $weekday요일',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${now.day}',
                style: const TextStyle(
                  fontSize: 58,
                  fontWeight: FontWeight.w300,
                  color: AppColors.ink,
                  height: 1,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${now.month}월',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    '$weekday요일',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Add `_StatChips` widget**

```dart
class _StatChips extends StatelessWidget {
  const _StatChips({required this.summary});

  final DailySummary? summary;

  @override
  Widget build(BuildContext context) {
    final distanceKm = summary == null
        ? null
        : (summary!.totalDistanceMeters / 1000).toStringAsFixed(1);
    final visits = summary?.visitCount;
    final movingMin = summary?.movingMinutes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Wrap(
        spacing: 8,
        children: [
          _Chip(
            icon: Icons.directions_walk_outlined,
            value: distanceKm != null ? '${distanceKm}km' : '—',
            label: '이동',
          ),
          _Chip(
            icon: Icons.place_outlined,
            value: visits != null ? '$visits곳' : '—',
            label: '방문',
          ),
          _Chip(
            icon: Icons.timer_outlined,
            value: movingMin != null ? '${movingMin}분' : '—',
            label: '이동 시간',
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.muted),
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Update `build()` in `_HomeScreenState`** — replace the `ListView` children

The entire `build()` `ListView` children block (~line 91–116) becomes:

```dart
        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _DateHero(isTracking: data.isTracking),
            const SizedBox(height: 2),
            _StatChips(summary: data.todayDailySummary),
            const SizedBox(height: 14),
            _DarkInsightCard(
              insight: data.latestInsight,
              onOpen: widget.onOpenLatestInsight,
            ),
            _SectionHeader(
              title: '오늘 흐름',
              actionLabel: '전체 보기',
              onAction: widget.onOpenTodayRecords,
            ),
            _DotTimeline(items: data.timeline),
            const SizedBox(height: 4),
            _QuickActionCard(dependencies: widget.dependencies),
            const SizedBox(height: 12),
          ],
        );
```

- [ ] **Step 4: Remove old widgets** — delete the following class definitions from `home_screen.dart`:
  - `_StatusPanel` (lines ~280–328)
  - `_TodayRecordPanel` (lines ~219–278)

- [ ] **Step 5: Analyze**

```bash
flutter analyze lib/features/home/home_screen.dart
```

Expected: errors for `_DarkInsightCard`, `_SectionHeader`, `_DotTimeline`, `_QuickActionCard` — those are added in Task 3. If other errors exist, fix them now.

- [ ] **Step 6: Commit**

```bash
git add lib/features/home/home_screen.dart
git commit -m "feat(home): add date hero and stats chips, remove status/record panels"
```

---

## Task 3 — HomeScreen: dark insight card, dot timeline, quick action

**Files:**
- Modify: `lib/features/home/home_screen.dart`

- [ ] **Step 1: Add `_SectionHeader` widget**

```dart
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 18, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.blueGrey,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Add `_DarkInsightCard` widget** (replaces `_InsightPanel` and `_EmptyPanel`)

```dart
class _DarkInsightCard extends StatelessWidget {
  const _DarkInsightCard({required this.insight, required this.onOpen});

  final Insight? insight;
  final ValueChanged<Insight>? onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: insight != null ? () => onOpen?.call(insight!) : null,
          child: DecoratedBox(
            decoration: AppThemeDecorations.inkCard(),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: insight == null
                  ? _EmptyInsightBody()
                  : _FilledInsightBody(insight: insight!),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyInsightBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘의 흐름',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.softBlue,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 10),
        Text(
          '아직 돌아볼 하루가 없어요',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.surface,
            height: 1.4,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '하루 정도 기록이 쌓이면 조용히 정리해드릴게요.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0x99FCFDFE),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _FilledInsightBody extends StatelessWidget {
  const _FilledInsightBody({required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘의 흐름',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.softBlue,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          insight.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.surface,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          insight.body,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0x99FCFDFE),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                child: Text(
                  '자세히',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Add `_DotTimeline` widget** (replaces `_TodayTimelinePanel` and `_TimelineRow`)

```dart
class _DotTimeline extends StatelessWidget {
  const _DotTimeline({required this.items});

  final List<DayTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(3).toList();
    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
        child: Text(
          '기록이 쌓이면 오늘 머문 곳이 시간순으로 보여요.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.muted,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++)
            _DotTimelineRow(
              item: visible[i],
              isLast: i == visible.length - 1,
            ),
        ],
      ),
    );
  }
}

class _DotTimelineRow extends StatelessWidget {
  const _DotTimelineRow({required this.item, required this.isLast});

  final DayTimelineItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                item.timeLabel,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Dot + line column
          Column(
            children: [
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bg, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.border,
                      blurRadius: 0,
                      spreadRadius: 1.5,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: AppColors.border,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.placeLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.durationLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

Note: `AppColors.bg` does not exist yet — add it to `app_theme.dart`:
```dart
static const bg = Color(0xFFEDF3F7); // same as background, alias for dot border
```

- [ ] **Step 4: Add `_QuickActionCard` widget**

```dart
class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      await widget.dependencies.runDailyProcessingNow();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _busy ? null : _run,
          child: DecoratedBox(
            decoration: AppThemeDecorations.quietPanel(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.refresh_outlined,
                        size: 18,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '지금 하루 정리하기',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '최신 패턴으로 흐름을 업데이트해요',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_busy)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.muted,
                      ),
                    )
                  else
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.border,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Delete old widgets** no longer referenced:
  - `_EmptyPanel` class
  - `_InsightPanel` class
  - `_TodayTimelinePanel` class
  - `_TimelineRow` class

- [ ] **Step 6: Add `bg` alias to `app_theme.dart`**

In `lib/app/app_theme.dart`, inside `AppColors`, add:
```dart
static const bg = background; // alias used for dot borders
```

- [ ] **Step 7: Analyze and hot-reload**

```bash
flutter analyze lib/features/home/home_screen.dart lib/app/app_theme.dart
```

Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add lib/features/home/home_screen.dart lib/app/app_theme.dart
git commit -m "feat(home): add dark insight card, dot timeline, quick action card"
```

---

## Task 4 — App Shell: persistent header with tracking badge

**Files:**
- Modify: `lib/app/app.dart`

The shell adds a fixed header above the screen content: "하루 기록" app name on the left, and a small pill badge ("흐름 기록 중" with green dot, or "기록 꺼짐" in muted) on the right. The tracking state is loaded once in `initState` and refreshed when the tab changes.

- [ ] **Step 1: Add tracking state to `_DailyPatternShellState`**

Add fields and `initState` logic to the existing `_DailyPatternShellState`:

```dart
bool _isTracking = false;

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _importPendingLocationEvents();
    _refreshTrackingState();
  });
}

Future<void> _refreshTrackingState() async {
  final tracking = await widget.dependencies.trackingService.isTracking();
  if (!mounted) return;
  setState(() => _isTracking = tracking);
}
```

Also call `_refreshTrackingState()` inside `didChangeAppLifecycleState` when `state == AppLifecycleState.resumed`.

- [ ] **Step 2: Add `_AppHeader` widget** (add at the bottom of `app.dart`)

```dart
class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.isTracking});

  final bool isTracking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 8, 16, 0),
      color: AppColors.background,
      child: Row(
        children: [
          Text(
            '하루 기록',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          _TrackingBadge(isTracking: isTracking),
        ],
      ),
    );
  }
}

class _TrackingBadge extends StatelessWidget {
  const _TrackingBadge({required this.isTracking});

  final bool isTracking;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.paleBlue,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PulsingDot(active: isTracking),
            const SizedBox(width: 5),
            Text(
              isTracking ? '흐름 기록 중' : '기록 꺼짐',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.active});

  final bool active;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 0.35).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? const Color(0xFF3DAA72) : AppColors.muted;
    if (!widget.active) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
```

- [ ] **Step 3: Update `_DailyPatternShellState.build()` to include the header**

In `app.dart`, find the `build` method of `_DailyPatternShellState`. Change the `Scaffold` body from:

```dart
body: screens[_selectedIndex],
```

To:

```dart
body: Column(
  children: [
    _AppHeader(isTracking: _isTracking),
    Expanded(child: screens[_selectedIndex]),
  ],
),
```

- [ ] **Step 4: Analyze**

```bash
flutter analyze lib/app/app.dart
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/app/app.dart
git commit -m "feat(shell): add persistent app header with animated tracking badge"
```

---

## Task 5 — HistoryScreen: month-grouped card layout

**Files:**
- Modify: `lib/features/history/history_screen.dart`

Replace the flat `ListView` with month-grouped display. Each month gets a section label. Each insight gets a card showing: day number | vertical divider | type badge + title + meta row (distance + visit count). Type badge text comes from `insight.type` (already a string in the DB). Distance/visits come from querying `DailySummaries` for that date.

> **Scope note:** Loading DailySummary per insight would be N queries. Instead, load all DailySummaries once alongside insights and join in-memory.

- [ ] **Step 1: Update `_load()` to also fetch daily summaries**

Replace the current `_load()`:

```dart
Future<List<Insight>> _load() async {
  final insights = await widget.database
      .select(widget.database.insights)
      .get();
  return insights..sort((a, b) => b.date.compareTo(a.date));
}
```

With a new snapshot approach. First add a snapshot class at the bottom:

```dart
class _HistorySnapshot {
  const _HistorySnapshot({
    required this.insights,
    required this.summaryByDate,
  });

  final List<Insight> insights;
  final Map<String, DailySummary> summaryByDate;
}
```

Then update `_load()`:

```dart
Future<_HistorySnapshot> _load() async {
  final insights = await widget.database.select(widget.database.insights).get();
  insights.sort((a, b) => b.date.compareTo(a.date));

  final summaries = await widget.database.select(widget.database.dailySummaries).get();
  final summaryByDate = {for (final s in summaries) s.date: s};

  return _HistorySnapshot(insights: insights, summaryByDate: summaryByDate);
}
```

Also update the field type and `FutureBuilder` accordingly:

```dart
late Future<_HistorySnapshot> _insights;
```

- [ ] **Step 2: Update `build()` to use grouped layout**

Replace the entire `FutureBuilder` body in `build()`:

```dart
    return FutureBuilder<_HistorySnapshot>(
      future: _insights,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        if (data.insights.isEmpty) {
          return const _HistoryExamples();
        }
        final grouped = _groupByMonth(data.insights);
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 32),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final item = grouped[index];
            if (item is _MonthHeader) {
              return _MonthLabelRow(label: item.label);
            }
            final insight = item as Insight;
            final dateKey = _dateKey(insight.date);
            final summary = data.summaryByDate[dateKey];
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _HistoryCard(
                insight: insight,
                summary: summary,
                onTap: () => _openDayDetail(insight),
              ),
            );
          },
        );
      },
    );
```

- [ ] **Step 3: Add helper types and functions**

```dart
class _MonthHeader {
  const _MonthHeader(this.label);
  final String label;
}

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

List<Object> _groupByMonth(List<Insight> insights) {
  final result = <Object>[];
  String? lastMonth;
  for (final insight in insights) {
    final monthKey =
        '${insight.date.year}-${insight.date.month.toString().padLeft(2, '0')}';
    if (monthKey != lastMonth) {
      result.add(_MonthHeader('${insight.date.year}년 ${insight.date.month}월'));
      lastMonth = monthKey;
    }
    result.add(insight);
  }
  return result;
}
```

- [ ] **Step 4: Add `_MonthLabelRow` and `_HistoryCard` widgets**

```dart
class _MonthLabelRow extends StatelessWidget {
  const _MonthLabelRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.insight,
    required this.summary,
    required this.onTap,
  });

  final Insight insight;
  final DailySummary? summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final dow = weekdays[insight.date.weekday - 1];
    final distanceKm = summary == null
        ? null
        : (summary!.totalDistanceMeters / 1000).toStringAsFixed(1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: DecoratedBox(
          decoration: AppThemeDecorations.softCard(),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day number column
                SizedBox(
                  width: 34,
                  child: Column(
                    children: [
                      Text(
                        '${insight.date.day}',
                        style: const TextStyle(
                          fontFamily: 'KyoboHandwriting',
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          color: AppColors.ink,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        dow,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Vertical divider
                Container(
                  width: 1,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: AppColors.border,
                ),
                // Body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.paleBlue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            insight.type,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.blueGrey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        insight.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (distanceKm != null) ...[
                            Text(
                              '${distanceKm}km',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (summary != null)
                            Text(
                              '${summary!.visitCount}곳 방문',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.border, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Remove old widgets** no longer used:
  - `_ExampleReflectionCard` class
  - `_HistoryExamples` class (keep or update — it no longer needs to match the old style; simplify to a plain empty state)

Update `_HistoryExamples` to:
```dart
class _HistoryExamples extends StatelessWidget {
  const _HistoryExamples();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          '하루 정도 기록이 쌓이면\n조용히 정리해드릴게요.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.muted,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Update `_dateLabel` helper** (no longer used for display, but `_openDayDetail` still needs the date — keep `_openDayDetail` as-is)

Remove `_dateLabel` since it's no longer called.

- [ ] **Step 7: Analyze**

```bash
flutter analyze lib/features/history/history_screen.dart
```

Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add lib/features/history/history_screen.dart
git commit -m "feat(history): month-grouped layout with day-number card design"
```

---

## Task 6 — PlaceManagementScreen: featured + 2-column grid

**Files:**
- Modify: `lib/features/places/place_management_screen.dart`

Replace the `ListView` with: first item = full-width "featured" card (rank 1), remaining items = 2-column grid rows. Each card shows: emoji icon placeholder, place name, visit count, and a frequency bar (visit count / max visit count).

- [ ] **Step 1: Replace `build()` list content**

Find the `ListView.separated` in the `FutureBuilder` body and replace with:

```dart
        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _PlacesPageHeader(),
            if (places.isNotEmpty)
              _FeaturedPlaceCard(
                place: places.first,
                onTap: () => _rename(places.first),
              ),
            if (places.length > 1)
              _PlaceGrid(
                places: places.skip(1).toList(),
                maxVisitCount: places.first.visitCount,
                onTap: _rename,
              ),
          ],
        );
```

For the `_PlaceExamples()` empty case, keep it but update styling (see Step 4).

- [ ] **Step 2: Add `_PlacesPageHeader`**

```dart
class _PlacesPageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(22, 14, 22, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '자주 간 곳',
            style: TextStyle(
              fontFamily: 'KyoboHandwriting',
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 3),
          Text(
            '자주 머문 곳들이에요',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Add `_FeaturedPlaceCard`**

```dart
class _FeaturedPlaceCard extends StatelessWidget {
  const _FeaturedPlaceCard({required this.place, required this.onTap});

  final PlaceCluster place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: DecoratedBox(
            decoration: AppThemeDecorations.softCard(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.paleBlue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.place_outlined,
                          color: AppColors.blueGrey,
                          size: 24,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.ink,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '1',
                              style: TextStyle(
                                color: AppColors.surface,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.displayName ?? '이름을 정하지 않은 곳',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${place.visitCount}번 방문 · 가장 자주 간 곳',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    '1',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.border,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Add `_PlaceGrid` + `_PlaceGridCard`**

```dart
class _PlaceGrid extends StatelessWidget {
  const _PlaceGrid({
    required this.places,
    required this.maxVisitCount,
    required this.onTap,
  });

  final List<PlaceCluster> places;
  final int maxVisitCount;
  final void Function(PlaceCluster) onTap;

  @override
  Widget build(BuildContext context) {
    // Build pairs of 2 as Rows
    final rows = <Widget>[];
    for (var i = 0; i < places.length; i += 2) {
      final left = places[i];
      final right = i + 1 < places.length ? places[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: _PlaceGridCard(
                  place: left,
                  rank: i + 2,
                  maxVisitCount: maxVisitCount,
                  onTap: () => onTap(left),
                ),
              ),
              const SizedBox(width: 10),
              if (right != null)
                Expanded(
                  child: _PlaceGridCard(
                    place: right,
                    rank: i + 3,
                    maxVisitCount: maxVisitCount,
                    onTap: () => onTap(right),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _PlaceGridCard extends StatelessWidget {
  const _PlaceGridCard({
    required this.place,
    required this.rank,
    required this.maxVisitCount,
    required this.onTap,
  });

  final PlaceCluster place;
  final int rank;
  final int maxVisitCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fraction = maxVisitCount > 0 ? place.visitCount / maxVisitCount : 0.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: DecoratedBox(
          decoration: AppThemeDecorations.softCard(),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.paleBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.place_outlined,
                    color: AppColors.blueGrey,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  place.displayName ?? '이름 없음',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${place.visitCount}번 방문',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                // Frequency bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 3,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.softBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Update empty state**

Replace `_PlaceExamples` and `_ExamplePlaceCard` with:

```dart
class _PlaceExamples extends StatelessWidget {
  const _PlaceExamples();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          '기록이 쌓이면\n자주 머문 곳이 보여요.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.muted,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}
```

Delete `_ExamplePlaceCard`.

- [ ] **Step 6: Analyze**

```bash
flutter analyze lib/features/places/place_management_screen.dart
```

Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add lib/features/places/place_management_screen.dart
git commit -m "feat(places): featured card + 2-column grid with frequency bar"
```

---

## Task 7 — SettingsScreen: grouped sections layout

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`

Add a page title header, replace the status area with a simpler status card, and group settings rows into labelled sections (기록, 알림, 데이터). The existing logic (`_toggleTracking`, `_toggleNotifications`, `_editNumber`, `_editNotificationTime`, delete buttons) is unchanged.

- [ ] **Step 1: Add `_SettingsPageHeader` widget**

```dart
class _SettingsPageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(22, 14, 22, 14),
      child: Text(
        '설정',
        style: TextStyle(
          fontFamily: 'KyoboHandwriting',
          fontSize: 26,
          fontWeight: FontWeight.w400,
          color: AppColors.ink,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add `_SettingsStatusCard` widget** (replaces `_SettingsStatusArea` as the top element in the list)

```dart
class _SettingsStatusCard extends StatelessWidget {
  const _SettingsStatusCard({required this.isTracking, required this.message});

  final bool isTracking;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final label = message ?? (isTracking ? '흐름 기록 중' : '기록 꺼짐');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DecoratedBox(
        decoration: AppThemeDecorations.quietPanel(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isTracking
                      ? const Color(0xFF3DAA72)
                      : AppColors.muted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Add `_SettingsSectionLabel` and `_SettingsGroup` widgets**

```dart
class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 5),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: AppThemeDecorations.softCard(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(children: children),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Add `_SettingsRow` widget** (unified replacement for `SwitchListTile` and `_EditableSettingsValueTile`)

```dart
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.paleBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.blueGrey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: row,
      ),
    );
  }
}
```

- [ ] **Step 5: Rewrite the `build()` `ListView` children**

In `_SettingsScreenState.build()`, replace the `Column` + inner `ListView` with a flat `ListView` structure:

```dart
        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _SettingsPageHeader(),
            _SettingsStatusCard(
              isTracking: settings.trackingEnabled,
              message: _status,
            ),
            const _SettingsSectionLabel(label: '기록'),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  key: const ValueKey('tracking-switch'),
                  icon: Icons.place_outlined,
                  label: '하루 기록',
                  subtitle: settings.trackingEnabled
                      ? '오늘의 흐름을 기록하고 있어요'
                      : '꺼져 있어요',
                  trailing: Switch(
                    value: settings.trackingEnabled,
                    onChanged: _busy
                        ? null
                        : (v) => _toggleTracking(settings, v),
                  ),
                  isFirst: true,
                ),
                const Divider(height: 1, color: AppColors.border),
                _SettingsRow(
                  key: const ValueKey('movement-threshold-edit'),
                  icon: Icons.directions_walk_outlined,
                  label: '이동 감지 거리',
                  subtitle: '이 거리 이상이면 이동으로 봐요',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${settings.minimumMovementMeters}m',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: AppColors.border, size: 18),
                    ],
                  ),
                  onTap: () => _editNumber(
                    title: '이동 감지 거리',
                    initialValue: settings.minimumMovementMeters,
                    suffix: 'm',
                    onSave: (v) => _save(settings.copyWith(minimumMovementMeters: v)),
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                _SettingsRow(
                  key: const ValueKey('stay-threshold-edit'),
                  icon: Icons.timer_outlined,
                  label: '머문 곳 기준 시간',
                  subtitle: '이 시간 이상 머물면 방문으로 봐요',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${settings.minimumStayMinutes}분',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: AppColors.border, size: 18),
                    ],
                  ),
                  onTap: () => _editNumber(
                    title: '머문 곳으로 볼 시간',
                    initialValue: settings.minimumStayMinutes,
                    suffix: '분',
                    onSave: (v) => _save(settings.copyWith(minimumStayMinutes: v)),
                  ),
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 6),
            const _SettingsSectionLabel(label: '알림'),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  key: const ValueKey('notification-switch'),
                  icon: Icons.notifications_outlined,
                  label: '돌아보기 알림',
                  subtitle: settings.notificationEnabled
                      ? '어제 하루가 정리되면 알려드릴게요'
                      : '꺼져 있어요',
                  trailing: Switch(
                    value: settings.notificationEnabled,
                    onChanged: _busy
                        ? null
                        : (v) => _toggleNotifications(settings, v),
                  ),
                  isFirst: true,
                ),
                const Divider(height: 1, color: AppColors.border),
                _SettingsRow(
                  key: const ValueKey('notification-time-edit'),
                  icon: Icons.access_time_outlined,
                  label: '알림 시간',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${settings.notificationHour.toString().padLeft(2, '0')}:'
                        '${settings.notificationMinute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: AppColors.border, size: 18),
                    ],
                  ),
                  onTap: () => _editNotificationTime(settings),
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 6),
            const _SettingsSectionLabel(label: '데이터'),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  key: const ValueKey('retention-days-edit'),
                  icon: Icons.storage_outlined,
                  label: '기록 보관 기간',
                  subtitle: '오래된 위치 데이터는 자동 삭제돼요',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${settings.rawPointRetentionDays}일',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: AppColors.border, size: 18),
                    ],
                  ),
                  onTap: () => _editNumber(
                    title: '기록 보관 기간',
                    initialValue: settings.rawPointRetentionDays,
                    suffix: '일',
                    onSave: (v) => _save(settings.copyWith(rawPointRetentionDays: v)),
                  ),
                  isFirst: true,
                ),
                const Divider(height: 1, color: AppColors.border),
                _SettingsRow(
                  key: const ValueKey('delete-raw-points-button'),
                  icon: Icons.delete_sweep_outlined,
                  label: '위치 기록 비우기',
                  subtitle: '돌아보기와 요약은 유지돼요',
                  onTap: _busy ? null : _confirmDeleteRawPoints,
                ),
                const Divider(height: 1, color: AppColors.border),
                _SettingsRow(
                  icon: Icons.delete_forever_outlined,
                  label: '이 기기의 기록 모두 지우기',
                  onTap: _busy ? null : _confirmDeleteAllLocalData,
                  isLast: true,
                ),
              ],
            ),
            if (widget.dependencies.showDebugValidationTools) ...[
              const _SettingsSectionLabel(label: '개발자'),
              _SettingsGroup(
                children: [
                  _SettingsRow(
                    icon: Icons.bug_report_outlined,
                    label: '검증용 어제 기록 넣기',
                    onTap: _busy ? null : _seedDebugYesterdayVisit,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                onPressed: _busy ? null : _runProcessing,
                icon: const Icon(Icons.play_arrow),
                label: const Text('어제 돌아보기 만들기'),
              ),
            ),
          ],
        );
```

- [ ] **Step 6: Remove unused widgets**

Delete:
- `_TrustCard` class
- `_SettingsStatusArea` class
- `_EditableSettingsValueTile` class

- [ ] **Step 7: Analyze**

```bash
flutter analyze lib/features/settings/settings_screen.dart
```

Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add lib/features/settings/settings_screen.dart
git commit -m "feat(settings): grouped sections layout with status card and unified row widget"
```

---

## Task 8 — Final verification

- [ ] **Step 1: Full analyze**

```bash
flutter analyze lib/
```

Expected: no errors.

- [ ] **Step 2: Run all tests**

```bash
flutter test
```

Expected: all pass. If any widget test references removed class names (`_StatusPanel`, `_TodayRecordPanel`, etc.), update the test to reference what actually exists now.

- [ ] **Step 3: Build debug APK (or iOS sim build)**

```bash
flutter build apk --debug
```

Expected: build succeeds.

- [ ] **Step 4: Visual check**

Open on a device or emulator. Compare each screen against `.docs/layout-preview.html` in a browser. Check:
- [ ] Home: date hero visible, 3 stat chips, dark card, dot timeline
- [ ] History: month headers, day-number cards
- [ ] Places: featured card full-width, 2-column grid below
- [ ] Settings: page title, status card, 3 grouped sections
- [ ] Shell header: app name + tracking badge visible on all tabs
- [ ] Tracking badge animates when tracking is on

- [ ] **Step 5: Final commit**

```bash
git add -p
git commit -m "feat: complete new Ink Journal layout across all screens"
```
