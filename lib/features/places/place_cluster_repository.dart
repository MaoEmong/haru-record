import 'package:drift/drift.dart' show Value;

import '../../core/geo/geo_math.dart';
import '../storage/app_database.dart';

class PlaceClusterMatch {
  const PlaceClusterMatch({required this.cluster, required this.isNew});

  final PlaceCluster cluster;
  final bool isNew;
}

class PlaceClusterRepository {
  const PlaceClusterRepository(this._database);

  final AppDatabase _database;

  Future<PlaceClusterMatch> findOrCreateForVisit({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required DateTime visitedAt,
  }) async {
    final clusters = await _database.select(_database.placeClusters).get();
    for (final cluster in clusters) {
      final distance = distanceMeters(
        cluster.centerLatitude,
        cluster.centerLongitude,
        latitude,
        longitude,
      );
      if (distance <= _matchingRadius(cluster.radiusMeters, radiusMeters)) {
        await (_database.update(_database.placeClusters)
              ..where((row) => row.id.equals(cluster.id)))
            .write(PlaceClustersCompanion(updatedAt: Value(visitedAt)));
        final updated = await (_database.select(_database.placeClusters)
              ..where((row) => row.id.equals(cluster.id)))
            .getSingle();
        return PlaceClusterMatch(cluster: updated, isNew: false);
      }
    }

    final id = await _database
        .into(_database.placeClusters)
        .insert(
          PlaceClustersCompanion.insert(
            centerLatitude: latitude,
            centerLongitude: longitude,
            radiusMeters: radiusMeters,
            createdAt: visitedAt,
            updatedAt: visitedAt,
            visitCount: 0,
          ),
        );
    final cluster = await (_database.select(_database.placeClusters)
          ..where((row) => row.id.equals(id)))
        .getSingle();
    return PlaceClusterMatch(cluster: cluster, isNew: true);
  }

  Future<void> recalculateVisitCounts() async {
    final clusters = await _database.select(_database.placeClusters).get();
    final visits = await _database.select(_database.visits).get();
    for (final cluster in clusters) {
      final visitCount = visits
          .where((visit) => visit.placeClusterId == cluster.id)
          .length;
      await (_database.update(_database.placeClusters)
            ..where((row) => row.id.equals(cluster.id)))
          .write(PlaceClustersCompanion(visitCount: Value(visitCount)));
    }
  }

  double _matchingRadius(double existingRadius, double requestedRadius) {
    return existingRadius > requestedRadius ? existingRadius : requestedRadius;
  }
}
