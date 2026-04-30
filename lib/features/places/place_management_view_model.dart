import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_database.dart';

final placesSnapshotProvider =
    FutureProvider.family<PlacesSnapshot, PlacesQuery>((ref, query) {
      return loadPlacesSnapshot(query.database);
    });

class PlacesQuery {
  const PlacesQuery({required this.database, required this.refreshVersion});

  final AppDatabase database;
  final int refreshVersion;

  @override
  bool operator ==(Object other) {
    return other is PlacesQuery &&
        identical(database, other.database) &&
        refreshVersion == other.refreshVersion;
  }

  @override
  int get hashCode => Object.hash(identityHashCode(database), refreshVersion);
}

class PlacesSnapshot {
  const PlacesSnapshot({
    required this.places,
    required this.featuredPlace,
    required this.namedPlaces,
    required this.unnamedPlaces,
  });

  final List<PlaceCluster> places;
  final PlaceCluster? featuredPlace;
  final List<PlaceCluster> namedPlaces;
  final List<PlaceCluster> unnamedPlaces;

  int get topVisitCount => places.isEmpty ? 1 : places.first.visitCount;
}

Future<PlacesSnapshot> loadPlacesSnapshot(AppDatabase database) async {
  final places = await database.select(database.placeClusters).get();
  final sorted = places..sort((a, b) => b.visitCount.compareTo(a.visitCount));
  final featuredPlace = sorted.firstOrNull;
  final remaining = sorted
      .where((place) => featuredPlace == null || place.id != featuredPlace.id)
      .toList(growable: false);

  return PlacesSnapshot(
    places: sorted,
    featuredPlace: featuredPlace,
    namedPlaces: remaining.where(hasPlaceDisplayName).toList(growable: false),
    unnamedPlaces: remaining
        .where((place) => !hasPlaceDisplayName(place))
        .toList(growable: false),
  );
}

Future<void> renamePlace(
  AppDatabase database,
  PlaceCluster place,
  String name,
) async {
  final normalized = name.trim();
  await (database.update(
    database.placeClusters,
  )..where((row) => row.id.equals(place.id))).write(
    PlaceClustersCompanion(
      displayName: Value(normalized.isEmpty ? null : normalized),
      updatedAt: Value(DateTime.now()),
    ),
  );
}

bool hasPlaceDisplayName(PlaceCluster place) {
  return place.displayName != null && place.displayName!.trim().isNotEmpty;
}

String placeAreaLabel(PlaceCluster place) {
  return place.roadAddressName ??
      place.addressName ??
      place.regionName ??
      '위치 기록 ${place.centerLatitude.toStringAsFixed(4)}, '
          '${place.centerLongitude.toStringAsFixed(4)}';
}
