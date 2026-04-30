import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../places/place_cluster_repository.dart';
import '../settings/settings_repository.dart';
import '../storage/app_database.dart';
import 'day_activity_preview_repository.dart';
import 'day_route_models.dart';
import 'day_route_repository.dart';
import 'day_timeline_models.dart';

final dayDetailPreviewProvider =
    FutureProvider.family<DayActivityPreview, DayDetailQuery>((ref, query) {
      if (query.refreshVersion == 0 && query.initialPreview != null) {
        return query.initialPreview!;
      }
      return loadDayDetailPreview(query);
    });

final dayDetailRouteProvider =
    FutureProvider.family<DayRouteSnapshot, DayDetailQuery>((ref, query) {
      if (query.refreshVersion == 0 && query.initialRoute != null) {
        return query.initialRoute!;
      }
      return loadDayDetailRoute(query);
    });

class DayDetailQuery {
  const DayDetailQuery({
    required this.database,
    required this.settingsRepository,
    required this.date,
    required this.refreshVersion,
    required this.initialPreview,
    required this.initialRoute,
  });

  final AppDatabase database;
  final SettingsRepository? settingsRepository;
  final DateTime date;
  final int refreshVersion;
  final DayActivityPreview? initialPreview;
  final Future<DayRouteSnapshot>? initialRoute;

  @override
  bool operator ==(Object other) {
    return other is DayDetailQuery &&
        identical(database, other.database) &&
        identical(settingsRepository, other.settingsRepository) &&
        date == other.date &&
        refreshVersion == other.refreshVersion &&
        identical(initialPreview, other.initialPreview) &&
        identical(initialRoute, other.initialRoute);
  }

  @override
  int get hashCode => Object.hash(
    identityHashCode(database),
    identityHashCode(settingsRepository),
    date,
    refreshVersion,
    identityHashCode(initialPreview),
    identityHashCode(initialRoute),
  );
}

Future<DayActivityPreview> loadDayDetailPreview(DayDetailQuery query) async {
  final settings = await (query.settingsRepository ?? SettingsRepository())
      .load();
  return DayActivityPreviewRepository(
    query.database,
  ).loadForDate(query.date, settings: settings);
}

Future<DayRouteSnapshot> loadDayDetailRoute(DayDetailQuery query) {
  return DayRouteRepository(query.database).loadForDate(query.date);
}

Future<void> saveTimelinePlace(
  AppDatabase database,
  DayTimelineItem item,
  String name,
) async {
  if (!item.canSaveAsPlace) return;

  final repository = PlaceClusterRepository(database);
  final match = await repository.findOrCreateForVisit(
    latitude: item.latitude!,
    longitude: item.longitude!,
    radiusMeters: 80,
    visitedAt: item.startedAt!,
  );
  final normalizedName = name.trim();
  if (normalizedName.isNotEmpty || match.isNew) {
    await (database.update(
      database.placeClusters,
    )..where((row) => row.id.equals(match.cluster.id))).write(
      PlaceClustersCompanion(
        displayName: Value(
          normalizedName.isEmpty ? '이름 없는 장소' : normalizedName,
        ),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
  await database
      .into(database.visits)
      .insert(
        VisitsCompanion.insert(
          placeClusterId: Value(match.cluster.id),
          startedAt: item.startedAt!,
          endedAt: item.endedAt!,
          durationMinutes: item.durationMinutes!,
          representativeLatitude: item.latitude!,
          representativeLongitude: item.longitude!,
        ),
      );
  await repository.recalculateVisitCounts();
}

DayTimelineItem? firstSaveableTimelineItem(List<DayTimelineItem> items) {
  for (final item in items) {
    if (item.canSaveAsPlace) return item;
  }
  return null;
}
