part of 'day_detail_screen.dart';

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({required this.items, required this.onSavePlace});

  final List<DayTimelineItem> items;
  final ValueChanged<DayTimelineItem> onSavePlace;

  @override
  Widget build(BuildContext context) {
    final routeLabel = items.isEmpty
        ? '아직 흐름을 만들 기록이 없어요'
        : items.map((item) => item.placeLabel).join(' -> ');
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '장소 흐름',
              style: TextStyle(
                fontSize: responsiveTitleFontSize(context, 18),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              routeLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final item in items)
              _TimelineDetailRow(item: item, onSavePlace: onSavePlace),
          ],
        ),
      ),
    );
  }
}

class _TimelineDetailRow extends StatelessWidget {
  const _TimelineDetailRow({required this.item, required this.onSavePlace});

  final DayTimelineItem item;
  final ValueChanged<DayTimelineItem> onSavePlace;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            item.timeLabel,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            '${item.placeLabel} · ${item.durationLabel}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        if (item.canSaveAsPlace) ...[
          const SizedBox(width: 8),
          const Text(
            '저장',
            style: TextStyle(
              color: AppColors.blueGrey,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: item.canSaveAsPlace ? () => onSavePlace(item) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: row,
        ),
      ),
    );
  }
}
