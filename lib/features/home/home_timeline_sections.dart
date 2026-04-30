part of 'home_screen.dart';

class _CurrentLocationCard extends StatelessWidget {
  const _CurrentLocationCard({required this.item});

  final DayTimelineItem? item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('현재 위치'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.mpSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.mpAccent.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.mpSurface2,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.place_rounded,
                    color: AppColors.mpAccent,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item?.placeLabel ?? '기록 대기 중',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.mpText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item == null
                            ? '위치 기록이 쌓이면 여기에 표시돼요'
                            : '${item!.timeLabel} 기록',
                        style: const TextStyle(
                          color: AppColors.mpTextSub,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 92),
                  child: Text(
                    item?.durationLabel ?? '--',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.mpAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayVisitList extends StatelessWidget {
  const _TodayVisitList({
    required this.preview,
    required this.route,
    required this.items,
    required this.onOpen,
    required this.isLoading,
  });

  final DayActivityPreview preview;
  final Future<DayRouteSnapshot> route;
  final List<DayTimelineItem> items;
  final OpenTodayRecordsCallback? onOpen;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(5).toList(growable: false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _SectionLabel('오늘 방문한 곳')),
              TextButton(
                onPressed: onOpen == null
                    ? null
                    : () => onOpen!(preview, route),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.mpAccent,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('오늘 기록'),
              ),
            ],
          ),
          if (visible.isEmpty)
            Text(
              isLoading ? '오늘 기록을 정리하는 중이에요' : '기록이 쌓이면 오늘 머문 곳이 시간순으로 보여요.',
              style: const TextStyle(color: AppColors.mpTextSub, fontSize: 13),
            )
          else
            for (var index = 0; index < visible.length; index++)
              _VisitTrackRow(index: index, item: visible[index]),
        ],
      ),
    );
  }
}

class _VisitTrackRow extends StatelessWidget {
  const _VisitTrackRow({required this.index, required this.item});

  final int index;
  final DayTimelineItem item;

  @override
  Widget build(BuildContext context) {
    final isCurrent = index == 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.mpSurface)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              isCurrent ? '●' : '${index + 1}',
              style: TextStyle(
                color: isCurrent ? AppColors.mpAccent : AppColors.mpTextSub,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.mpSurface,
              borderRadius: BorderRadius.circular(6),
              border: isCurrent
                  ? Border.all(color: AppColors.mpAccent.withValues(alpha: 0.4))
                  : null,
            ),
            child: const Icon(
              Icons.album_rounded,
              color: AppColors.mpTextSub,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.placeLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent ? AppColors.mpAccent : AppColors.mpText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.timeLabel,
                  style: TextStyle(
                    color: isCurrent ? AppColors.mpAccent : AppColors.mpTextSub,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 84),
            child: Text(
              item.durationLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isCurrent ? AppColors.mpAccent : AppColors.mpTextSub,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: insight == null ? null : () => onOpen?.call(insight!),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.mpSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.mpBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최근 돌아보기',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.mpAccent,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '아직 돌아볼 하루가 없어요',
          style: TextStyle(
            color: AppColors.mpText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 5),
        Text(
          '하루 정도 기록이 쌓이면 조용히 정리해드릴게요.',
          style: TextStyle(fontSize: 13, color: AppColors.mpTextSub),
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
            fontWeight: FontWeight.w800,
            color: AppColors.mpAccent,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          insight.title,
          style: const TextStyle(
            color: AppColors.mpText,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          insight.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.mpTextSub,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.mpTextSub,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _GreenDot extends StatelessWidget {
  const _GreenDot({this.size = 8});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.mpAccent,
        shape: BoxShape.circle,
      ),
    );
  }
}
