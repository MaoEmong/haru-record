import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_theme.dart';
import '../settings/settings_models.dart';
import '../storage/app_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.dependencies,
    required this.refreshVersion,
  });

  final AppDependencies dependencies;
  final int refreshVersion;

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
    final todayPointCount = await _loadTodayPointCount();
    insights.sort((a, b) => b.date.compareTo(a.date));
    return _HomeSnapshot(
      settings: settings,
      isTracking: isTracking,
      latestInsight: insights.firstOrNull,
      todayPointCount: todayPointCount,
    );
  }

  Future<int> _loadTodayPointCount() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final points = await widget.dependencies.database
        .select(widget.dependencies.database.locationPoints)
        .get();
    return points
        .where(
          (point) =>
              !point.timestamp.isBefore(start) && point.timestamp.isBefore(end),
        )
        .length;
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
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _StatusPanel(snapshot: data),
            const SizedBox(height: 12),
            _TodayRecordPanel(snapshot: data),
            const SizedBox(height: 22),
            Text('최근 돌아보기', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (data.latestInsight == null)
              const _EmptyPanel()
            else
              _InsightPanel(insight: data.latestInsight!),
          ],
        );
      },
    );
  }
}

class _TodayRecordPanel extends StatelessWidget {
  const _TodayRecordPanel({required this.snapshot});

  final _HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final isRecording =
        snapshot.isTracking || snapshot.settings.trackingEnabled;
    final title = switch (snapshot.todayPointCount) {
      0 when isRecording => '아직 오늘 남긴 기록은 없어요',
      0 => '하루 기록을 켜면 오늘의 흐름이 쌓여요',
      _ => '오늘은 ${snapshot.todayPointCount}개의 기록이 조용히 쌓였어요',
    };
    final subtitle = snapshot.todayPointCount == 0
        ? '움직임이 충분히 쌓이면 이곳에서 바로 확인할 수 있어요.'
        : '자세한 위치는 기기 안에만 머물고, 하루 단위로 가볍게 정리돼요.';

    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '오늘 남긴 기록',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.snapshot});

  final _HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final isRecording =
        snapshot.isTracking || snapshot.settings.trackingEnabled;
    final status = isRecording ? '오늘의 흐름을 기록하고 있어요' : '오늘의 흐름 기록이 쉬고 있어요';
    final subtitle = isRecording
        ? '기록은 내 기기에만 머물러요. 하루가 지나면 가볍게 정리해드릴게요.'
        : '설정에서 하루 기록을 켜면 움직임과 머문 곳을 조용히 정리해요.';
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(color: AppColors.surfaceAlt),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '하루 기록',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              status,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.more_horiz, color: AppColors.muted),
            SizedBox(height: 12),
            Text(
              '아직 돌아볼 하루가 없어요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6),
            Text(
              '하루 정도 기록이 쌓이면 조용히 정리해드릴게요.',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.inkCard(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('어제', style: TextStyle(color: Color(0xFFC6D2DC))),
            const SizedBox(height: 8),
            Text(
              insight.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              insight.body,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFDDE7EF)),
            ),
          ],
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
    required this.todayPointCount,
  });

  final AppSettings settings;
  final bool isTracking;
  final Insight? latestInsight;
  final int todayPointCount;
}
