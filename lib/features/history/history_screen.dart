import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
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
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          itemCount: insights.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final insight = insights[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _openDayDetail(insight),
                child: DecoratedBox(
                  decoration: AppThemeDecorations.softCard(),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    title: Text(
                      insight.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${_dateLabel(insight.date)}\n${insight.body}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.muted,
                    ),
                    isThreeLine: true,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _dateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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

class _HistoryExamples extends StatelessWidget {
  const _HistoryExamples();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: const [
        Text(
          '이런 식으로 하루가 정리돼요',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 10),
        _ExampleReflectionCard(
          title: '어제는 조금 조용한 하루였어요',
          body: '최근 며칠보다 이동이 적고 차분했어요.',
        ),
        SizedBox(height: 10),
        _ExampleReflectionCard(
          title: '어제는 평소보다 많이 움직였어요',
          body: '자주 머문 곳과 움직임이 하루 단위로 정리돼요.',
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
