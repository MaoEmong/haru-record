import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../shared/widgets/music_player_widgets.dart';
import '../storage/app_database.dart';
import '../timeline/day_activity_preview_repository.dart';
import '../timeline/day_detail_screen.dart';
import 'history_view_model.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({
    super.key,
    required this.database,
    required this.refreshVersion,
  });

  final AppDatabase database;
  final int refreshVersion;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  HistoryQuery get _query => HistoryQuery(
    database: widget.database,
    refreshVersion: widget.refreshVersion,
  );

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(historyDaysProvider(_query));
    return days.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('돌아보기를 불러오지 못했어요')),
      data: (days) {
        if (days.isEmpty) {
          return const _HistoryExamples();
        }
        return ListView(
          padding: EdgeInsets.only(
            bottom: 96 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            MpPageHeader(title: '돌아보기', subtitle: '${days.length}일의 하루'),
            const SizedBox(height: 6),
            for (final day in days)
              _HistoryTrackItem(day: day, onOpen: _openDayDetail),
          ],
        );
      },
    );
  }

  void _openDayDetail(HistoryDay day) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DayDetailScreen(
          database: widget.database,
          date: day.date,
          title: day.title,
          body: day.body,
          appBarTitle: day.insight == null ? '오늘 기록' : '하루 자세히 보기',
        ),
      ),
    );
  }
}

class _HistoryTrackItem extends ConsumerWidget {
  const _HistoryTrackItem({required this.day, required this.onOpen});

  final HistoryDay day;
  final ValueChanged<HistoryDay> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isToday = _isToday(day.date);
    final accent = isToday
        ? const Color(0xFF4A8AFF)
        : _accentForPastDay(day.date.day);
    final preview = ref.watch(
      historyDayPreviewProvider(
        HistoryPreviewQuery(
          database: day.database,
          date: day.date,
          refreshVersion: day.refreshVersion,
        ),
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onOpen(day),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AlbumArtCard(
                height: 52,
                borderRadius: 10,
                accent: accent,
                child: SizedBox(
                  width: 50,
                  child: Center(
                    child: Text(
                      day.date.day.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        color: AppColors.mpText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isToday ? AppColors.mpAccent : AppColors.mpText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _metaLabel(day, preview.value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isToday
                            ? AppColors.mpAccent
                            : AppColors.mpTextSub,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isToday)
                    const _LiveBars()
                  else
                    Text(
                      _recordedLabel(preview.value),
                      style: const TextStyle(
                        color: AppColors.mpTextSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.more_horiz_rounded,
                    color: isToday ? const Color(0xFF4A8AFF) : accent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) => isSameDate(date, DateTime.now());

  String _metaLabel(HistoryDay day, DayActivityPreview? preview) {
    final date = day.date;
    if (preview == null) {
      return '${date.month}월 ${date.day}일 · 기록 확인 중';
    }
    final distance = _distanceLabel(preview.totalDistanceMeters);
    final visits = preview.visitCount;
    final visitLabel = visits == null ? '방문 기록 없음' : '$visits곳';
    return '${date.month}월 ${date.day}일 · $distance · $visitLabel';
  }

  String _distanceLabel(double? meters) {
    if (meters == null) return '이동 기록 없음';
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.round()} m';
  }

  String _recordedLabel(DayActivityPreview? preview) {
    if (preview == null) return '--:--';
    final minutes = preview.timeline.fold<int>(
      0,
      (total, item) => total + (item.durationMinutes ?? 0),
    );
    if (minutes <= 0) return '--:--';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    return '$hours:${remain.toString().padLeft(2, '0')}';
  }

  Color _accentForPastDay(int day) {
    const colors = [
      Color(0xFFFF8A4A),
      Color(0xFFFFCA4A),
      AppColors.mpAccent,
      Color(0xFFE05F3C),
    ];
    return colors[day % colors.length];
  }
}

class _LiveBars extends StatefulWidget {
  const _LiveBars();

  @override
  State<_LiveBars> createState() => _LiveBarsState();
}

class _LiveBarsState extends State<_LiveBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;
        return SizedBox(
          width: 20,
          height: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _LiveBar(height: 5 + value * 8),
              const SizedBox(width: 2),
              _LiveBar(height: 12 - value * 5),
              const SizedBox(width: 2),
              _LiveBar(height: 7 + value * 7),
              const SizedBox(width: 2),
              _LiveBar(height: 14 - value * 6),
            ],
          ),
        );
      },
    );
  }
}

class _LiveBar extends StatelessWidget {
  const _LiveBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mpAccent,
        borderRadius: BorderRadius.circular(2),
      ),
      child: SizedBox(width: 3, height: height),
    );
  }
}

class _HistoryExamples extends StatelessWidget {
  const _HistoryExamples();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        bottom: 96 + MediaQuery.paddingOf(context).bottom,
      ),
      children: const [
        MpPageHeader(title: '돌아보기', subtitle: '0일의 하루들'),
        SizedBox(height: 18),
        _EmptyQueueMessage(),
        SizedBox(height: 18),
        _EmptyHistoryTrackRow(
          dayLabel: '01',
          title: '하루가 끝나면 여기에 쌓여요',
          meta: '방문한 곳 · 이동 경로 · 머문 흐름',
        ),
        _EmptyHistoryTrackRow(
          dayLabel: '02',
          title: '기록이 모이면 조용히 정리돼요',
          meta: '내일 아침, 어제의 하루를 돌아볼 수 있어요',
        ),
      ],
    );
  }
}

class _EmptyQueueMessage extends StatelessWidget {
  const _EmptyQueueMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.mpSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.mpBorder),
        ),
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '아직 재생할 하루가 없어요',
                style: TextStyle(
                  color: AppColors.mpText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '오늘 위치 기록이 쌓이면 내일 아침에 하루가 정리돼요.',
                style: TextStyle(
                  color: AppColors.mpTextSub,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistoryTrackRow extends StatelessWidget {
  const _EmptyHistoryTrackRow({
    required this.dayLabel,
    required this.title,
    required this.meta,
  });

  final String dayLabel;
  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.42,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AlbumArtCard(
              height: 52,
              borderRadius: 10,
              accent: AppColors.mpTextMuted,
              child: SizedBox(
                width: 50,
                child: Center(
                  child: Text(
                    dayLabel,
                    style: const TextStyle(
                      color: AppColors.mpText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mpText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mpTextSub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '--:--',
              style: TextStyle(
                color: AppColors.mpTextSub,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.more_horiz_rounded, color: AppColors.mpTextMuted),
          ],
        ),
      ),
    );
  }
}
