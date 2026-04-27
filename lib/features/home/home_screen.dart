import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';
import '../../app/responsive_type.dart';
import '../settings/settings_models.dart';
import '../storage/app_database.dart';
import '../timeline/day_activity_preview_repository.dart';
import '../timeline/day_timeline_models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.dependencies,
    required this.refreshVersion,
    this.onOpenTodayRecords,
    this.onOpenLatestInsight,
  });

  final AppDependencies dependencies;
  final int refreshVersion;
  final VoidCallback? onOpenTodayRecords;
  final ValueChanged<Insight>? onOpenLatestInsight;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeSnapshot> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = _load();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion) {
      setState(() {
        _snapshot = _load();
      });
    }
  }

  Future<_HomeSnapshot> _load() async {
    final settings = await widget.dependencies.settingsRepository.load();
    final isTracking = await widget.dependencies.trackingService.isTracking();
    final insights = await widget.dependencies.database
        .select(widget.dependencies.database.insights)
        .get();
    final todayPreview = await DayActivityPreviewRepository(
      widget.dependencies.database,
    ).loadForDate(DateTime.now());
    insights.sort((a, b) => b.date.compareTo(a.date));
    return _HomeSnapshot(
      settings: settings,
      isTracking: isTracking,
      latestInsight: insights.firstOrNull,
      todayPreview: todayPreview,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeSnapshot>(
      future: _snapshot,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final isRecording = data.isTracking || data.settings.trackingEnabled;
        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _DateHero(isTracking: isRecording),
            const SizedBox(height: 2),
            _StatChips(preview: data.todayPreview),
            const SizedBox(height: 14),
            _DarkInsightCard(
              insight: data.latestInsight,
              onOpen: widget.onOpenLatestInsight,
            ),
            _SectionHeader(
              title: '오늘의 흐름',
              actionLabel: '전체 보기',
              onAction: widget.onOpenTodayRecords,
            ),
            _DotTimeline(items: data.todayPreview.timeline),
            const SizedBox(height: 4),
            _QuickActionCard(onOpen: widget.onOpenTodayRecords),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _DateHero extends StatelessWidget {
  const _DateHero({required this.isTracking});

  final bool isTracking;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekday = _weekdayLabel(now.weekday);
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${now.year}년 · $weekday',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(width: 8),
              _RecordingPill(isRecording: isTracking),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${now.day}',
                style: TextStyle(
                  fontSize: responsiveTitleFontSize(
                    context,
                    58,
                    minScale: 0.92,
                    maxScale: 1.14,
                  ),
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
                    style: TextStyle(
                      fontSize: responsiveTitleFontSize(context, 19),
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    weekday,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    return const ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'][weekday - 1];
  }
}

class _RecordingPill extends StatelessWidget {
  const _RecordingPill({required this.isRecording});

  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isRecording ? AppColors.paleBlue : AppColors.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isRecording ? AppColors.blueGrey : AppColors.muted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              isRecording ? '기록 중' : '기록 쉼',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChips extends StatelessWidget {
  const _StatChips({required this.preview});

  final DayActivityPreview preview;

  @override
  Widget build(BuildContext context) {
    final distanceKm = preview.totalDistanceMeters == null
        ? null
        : (preview.totalDistanceMeters! / 1000).toStringAsFixed(1);
    final visits = preview.visitCount;
    final movingMin = preview.movingMinutes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Chip(
            icon: Icons.directions_walk_outlined,
            value: distanceKm != null ? '${distanceKm}km' : '--',
            label: '이동',
          ),
          _Chip(
            icon: Icons.place_outlined,
            value: visits != null ? '$visits곳' : '--',
            label: '방문',
          ),
          _Chip(
            icon: Icons.timer_outlined,
            value: movingMin != null ? '$movingMin분' : '--',
            label: '움직임',
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

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
          onTap: insight == null ? null : () => onOpen?.call(insight!),
          child: DecoratedBox(
            decoration: AppThemeDecorations.inkCard(),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: insight == null
                  ? const _EmptyInsightBody()
                  : _FilledInsightBody(insight: insight!),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyInsightBody extends StatelessWidget {
  const _EmptyInsightBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '최근 돌아보기',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.softBlue,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '아직 돌아볼 하루가 없어요',
          style: TextStyle(
            fontSize: responsiveTitleFontSize(context, 20),
            fontWeight: FontWeight.w500,
            color: AppColors.surface,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '하루 정도 기록이 쌓이면 조용히 정리해드릴게요.',
          style: TextStyle(fontSize: 13, color: Color(0x99FCFDFE), height: 1.6),
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
          '최근 돌아보기',
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
          style: TextStyle(
            fontSize: responsiveTitleFontSize(context, 20),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DotTimeline extends StatelessWidget {
  const _DotTimeline({required this.items});

  final List<DayTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(3).toList(growable: false);
    if (visible.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
        child: Text(
          '기록이 쌓이면 오늘 머문 곳이 시간순으로 보여요.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
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
          SizedBox(
            width: 52,
            child: Text(
              item.timeLabel,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.blueGrey,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.placeLabel,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.durationLabel,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
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

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.onOpen});

  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onOpen,
          child: DecoratedBox(
            decoration: AppThemeDecorations.softCard(color: AppColors.surface),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.article_outlined, color: AppColors.blueGrey),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '오늘 기록',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          '지금 기록된 위치와 머문 곳을 확인해요',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeSnapshot {
  const _HomeSnapshot({
    required this.settings,
    required this.isTracking,
    required this.latestInsight,
    required this.todayPreview,
  });

  final AppSettings settings;
  final bool isTracking;
  final Insight? latestInsight;
  final DayActivityPreview todayPreview;
}
