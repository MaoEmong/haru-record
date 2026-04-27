import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../storage/app_database.dart';
import 'day_timeline_models.dart';
import 'day_timeline_repository.dart';

class DayDetailScreen extends StatefulWidget {
  const DayDetailScreen({
    super.key,
    required this.database,
    required this.date,
    this.title,
    this.body,
  });

  final AppDatabase database;
  final DateTime date;
  final String? title;
  final String? body;

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  late Future<_DayDetailSnapshot> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = _load();
  }

  Future<_DayDetailSnapshot> _load() async {
    final timeline = await DayTimelineRepository(
      widget.database,
    ).loadForDate(widget.date);
    final summaries = await widget.database
        .select(widget.database.dailySummaries)
        .get();
    final dateKey = _dateKey(widget.date);
    DailySummary? summary;
    for (final item in summaries) {
      if (item.date == dateKey) {
        summary = item;
        break;
      }
    }
    return _DayDetailSnapshot(timeline: timeline, summary: summary);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('하루 자세히 보기')),
      body: SafeArea(
        child: FutureBuilder<_DayDetailSnapshot>(
          future: _snapshot,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _ReflectionHeader(
                  dateLabel: _dateKey(widget.date),
                  title: widget.title,
                  body: widget.body,
                ),
                const SizedBox(height: 12),
                _SummaryCard(summary: data.summary),
                const SizedBox(height: 12),
                _RouteSummaryCard(items: data.timeline),
              ],
            );
          },
        ),
      ),
    );
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _ReflectionHeader extends StatelessWidget {
  const _ReflectionHeader({
    required this.dateLabel,
    required this.title,
    required this.body,
  });

  final String dateLabel;
  final String? title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateLabel,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title ?? '하루 흐름',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(body!, style: const TextStyle(color: AppColors.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final DailySummary? summary;

  @override
  Widget build(BuildContext context) {
    final visitCount = summary?.visitCount ?? 0;
    final distance = summary?.totalDistanceMeters ?? 0;
    final movingMinutes = summary?.movingMinutes ?? 0;
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '하루 요약',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(label: '방문 $visitCount곳'),
                _MetricChip(label: '이동 ${_distanceLabel(distance)}'),
                _MetricChip(label: '움직임 $movingMinutes분'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _distanceLabel(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({required this.items});

  final List<DayTimelineItem> items;

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
            const Text(
              '장소 흐름',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              routeLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final item in items) _TimelineDetailRow(item: item),
          ],
        ),
      ),
    );
  }
}

class _TimelineDetailRow extends StatelessWidget {
  const _TimelineDetailRow({required this.item});

  final DayTimelineItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
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
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DayDetailSnapshot {
  const _DayDetailSnapshot({required this.timeline, required this.summary});

  final List<DayTimelineItem> timeline;
  final DailySummary? summary;
}
