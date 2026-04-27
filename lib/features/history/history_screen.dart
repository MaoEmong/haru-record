import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../app/responsive_type.dart';
import '../storage/app_database.dart';
import '../timeline/day_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.database,
    required this.refreshVersion,
  });

  final AppDatabase database;
  final int refreshVersion;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Insight>> _insights;

  @override
  void initState() {
    super.initState();
    _insights = _load();
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion) {
      setState(() {
        _insights = _load();
      });
    }
  }

  Future<List<Insight>> _load() async {
    final insights = await widget.database
        .select(widget.database.insights)
        .get();
    return insights..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Insight>>(
      future: _insights,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final insights = snapshot.data!;
        if (insights.isEmpty) {
          return const _HistoryExamples();
        }
        final grouped = _groupByMonth(insights);
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
            for (final entry in grouped.entries)
              _MonthSection(
                title: entry.key,
                insights: entry.value,
                onOpen: _openDayDetail,
              ),
          ],
        );
      },
    );
  }

  Map<String, List<Insight>> _groupByMonth(List<Insight> insights) {
    final grouped = <String, List<Insight>>{};
    for (final insight in insights) {
      final key =
          '${insight.date.year}년 ${insight.date.month.toString().padLeft(2, '0')}월';
      grouped.putIfAbsent(key, () => []).add(insight);
    }
    return grouped;
  }

  void _openDayDetail(Insight insight) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DayDetailScreen(
          database: widget.database,
          date: insight.date,
          title: insight.title,
          body: insight.body,
        ),
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({
    required this.title,
    required this.insights,
    required this.onOpen,
  });

  final String title;
  final List<Insight> insights;
  final ValueChanged<Insight> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          for (final insight in insights) ...[
            _HistoryCard(insight: insight, onOpen: onOpen),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.insight, required this.onOpen});

  final Insight insight;
  final ValueChanged<Insight> onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => onOpen(insight),
        child: DecoratedBox(
          decoration: AppThemeDecorations.softCard(),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  child: Column(
                    children: [
                      Text(
                        insight.date.day.toString().padLeft(2, '0'),
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: responsiveTitleFontSize(context, 24),
                          fontWeight: FontWeight.w300,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _weekdayLabel(insight.date.weekday),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: AppColors.border,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight.title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        insight.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    return const ['월', '화', '수', '목', '금', '토', '일'][weekday - 1];
  }
}

class _HistoryExamples extends StatelessWidget {
  const _HistoryExamples();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        Text(
          '이런 식으로 하루가 정리돼요',
          style: TextStyle(
            fontSize: responsiveTitleFontSize(context, 20),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const _ExampleReflectionCard(
          title: '어제는 조금 조용한 하루였어요',
          body: '최근 며칠보다 이동이 적고 차분했어요.',
        ),
        const SizedBox(height: 10),
        const _ExampleReflectionCard(
          title: '어제는 평소보다 많이 움직였어요',
          body: '방문한 곳과 움직임이 하루 단위로 정리돼요.',
        ),
      ],
    );
  }
}

class _ExampleReflectionCard extends StatelessWidget {
  const _ExampleReflectionCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '예시',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: responsiveTitleFontSize(context, 18),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
