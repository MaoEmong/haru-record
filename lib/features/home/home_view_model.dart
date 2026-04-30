import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_providers.dart';
import '../settings/settings_models.dart';
import '../storage/app_database.dart';
import '../timeline/day_activity_preview_repository.dart';
import '../timeline/day_route_models.dart';
import '../timeline/day_route_repository.dart';

final homeSettingsProvider = FutureProvider.family<AppSettings, int>((
  ref,
  refreshVersion,
) {
  final dependencies = ref.watch(appDependenciesProvider);
  return dependencies.settingsRepository.load();
});

final homeTrackingProvider = FutureProvider.family<bool, int>((
  ref,
  refreshVersion,
) {
  final dependencies = ref.watch(appDependenciesProvider);
  return dependencies.trackingService.isTracking();
});

final homeLatestInsightProvider = FutureProvider.family<Insight?, int>((
  ref,
  refreshVersion,
) async {
  final dependencies = ref.watch(appDependenciesProvider);
  return loadLatestInsight(dependencies);
});

final homePlacesProvider = FutureProvider.family<List<PlaceCluster>, int>((
  ref,
  refreshVersion,
) {
  final dependencies = ref.watch(appDependenciesProvider);
  return loadHomePlaces(dependencies);
});

final todayPreviewProvider = FutureProvider.family<DayActivityPreview, int>((
  ref,
  refreshVersion,
) async {
  final dependencies = ref.watch(appDependenciesProvider);
  final settings = await ref.watch(homeSettingsProvider(refreshVersion).future);
  return loadTodayPreview(dependencies, settings: settings);
});

final todayRouteSnapshotProvider = FutureProvider.family<DayRouteSnapshot, int>(
  (ref, refreshVersion) {
    final dependencies = ref.watch(appDependenciesProvider);
    return loadTodayRouteSnapshot(dependencies);
  },
);

class HomeSnapshot {
  const HomeSnapshot({
    required this.settings,
    required this.isTracking,
    required this.latestInsight,
    required this.todayPreview,
    required this.places,
  });

  final AppSettings settings;
  final bool isTracking;
  final Insight? latestInsight;
  final DayActivityPreview todayPreview;
  final List<PlaceCluster> places;
}

Future<HomeSnapshot> loadHomeSnapshot(AppDependencies dependencies) async {
  final today = DateTime.now();
  final settingsFuture = dependencies.settingsRepository.load();
  final trackingFuture = dependencies.trackingService.isTracking();
  final insightsFuture = dependencies.database
      .select(dependencies.database.insights)
      .get();
  final placesFuture = dependencies.database
      .select(dependencies.database.placeClusters)
      .get();
  final settings = await settingsFuture;
  final previewFuture = DayActivityPreviewRepository(
    dependencies.database,
  ).loadForDate(today, settings: settings);
  final results = await Future.wait([
    trackingFuture,
    insightsFuture,
    previewFuture,
    placesFuture,
  ]);

  final insights = results[1] as List<Insight>;
  insights.sort((a, b) => b.date.compareTo(a.date));
  return HomeSnapshot(
    settings: settings,
    isTracking: results[0] as bool,
    latestInsight: insights.firstOrNull,
    todayPreview: results[2] as DayActivityPreview,
    places: results[3] as List<PlaceCluster>,
  );
}

Future<DayRouteSnapshot> loadTodayRouteSnapshot(AppDependencies dependencies) {
  return DayRouteRepository(dependencies.database).loadForDate(DateTime.now());
}

Future<DayActivityPreview> loadTodayPreview(
  AppDependencies dependencies, {
  required AppSettings settings,
}) {
  return DayActivityPreviewRepository(
    dependencies.database,
  ).loadForDate(DateTime.now(), settings: settings);
}

Future<Insight?> loadLatestInsight(AppDependencies dependencies) async {
  final insights = await dependencies.database
      .select(dependencies.database.insights)
      .get();
  insights.sort((a, b) => b.date.compareTo(a.date));
  return insights.firstOrNull;
}

Future<List<PlaceCluster>> loadHomePlaces(AppDependencies dependencies) {
  return dependencies.database
      .select(dependencies.database.placeClusters)
      .get();
}
