import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../settings/settings_models.dart';
import '../storage/app_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.dependencies});

  final AppDependencies dependencies;

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

  Future<_HomeSnapshot> _load() async {
    final settings = await widget.dependencies.settingsRepository.load();
    final isTracking = await widget.dependencies.trackingService.isTracking();
    final insights = await widget.dependencies.database
        .select(widget.dependencies.database.insights)
        .get();
    insights.sort((a, b) => b.date.compareTo(a.date));
    return _HomeSnapshot(
      settings: settings,
      isTracking: isTracking,
      latestInsight: insights.firstOrNull,
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
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatusPanel(snapshot: data),
            const SizedBox(height: 16),
            Text(
              'Latest insight',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
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

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.snapshot});

  final _HomeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final status = snapshot.isTracking || snapshot.settings.trackingEnabled
        ? 'Tracking active'
        : 'Tracking paused';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Daily summaries use local location points and stay on this device.',
              style: Theme.of(context).textTheme.bodyMedium,
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
    return ListTile(
      tileColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: const Icon(Icons.insights_outlined),
      title: const Text('No insights yet'),
      subtitle: const Text('Run daily processing after location data exists.'),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: const Icon(Icons.insights),
      title: Text(insight.title),
      subtitle: Text(insight.body),
    );
  }
}

class _HomeSnapshot {
  const _HomeSnapshot({
    required this.settings,
    required this.isTracking,
    required this.latestInsight,
  });

  final AppSettings settings;
  final bool isTracking;
  final Insight? latestInsight;
}
