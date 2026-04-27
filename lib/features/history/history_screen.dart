import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../storage/app_database.dart';

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
          return const _EmptyHistory();
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: insights.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final insight = insights[index];
            return DecoratedBox(
              decoration: AppThemeDecorations.softCard(),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                title: Text(
                  insight.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${_dateLabel(insight.date)}\n${insight.body}',
                  style: const TextStyle(color: AppColors.muted),
                ),
                isThreeLine: true,
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
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('아직 돌아볼 하루가 없어요'),
      ),
    );
  }
}
