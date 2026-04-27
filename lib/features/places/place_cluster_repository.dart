import 'package:drift/drift.dart' show Value;

import '../../core/geo/geo_math.dart';
import '../storage/app_database.dart';
import 'kakao_reverse_geocoder.dart';
import 'place_address.dart';

class PlaceClusterMatch {
  const PlaceClusterMatch({required this.cluster, required this.isNew});

  final PlaceCluster cluster;
  final bool isNew;
}

class PlaceClusterRepository {
  PlaceClusterRepository(this._database, {ReverseGeocoder? reverseGeocoder})
    : _reverseGeocoder =
          reverseGeocoder ?? KakaoReverseGeocoder.fromEnvironment();

  final AppDatabase _database;
  final ReverseGeocoder? _reverseGeocoder;

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
        await _resolveAddressIfMissing(cluster);
        final updated = await (_database.select(
          _database.placeClusters,
        )..where((row) => row.id.equals(cluster.id))).getSingle();
        return PlaceClusterMatch(cluster: updated, isNew: false);
      }
    }

    final address = await _resolveAddress(
      latitude: latitude,
      longitude: longitude,
    );
    final id = await _database
        .into(_database.placeClusters)
        .insert(
          PlaceClustersCompanion.insert(
            centerLatitude: latitude,
            centerLongitude: longitude,
            radiusMeters: radiusMeters,
            addressName: Value(address?.addressName),
            roadAddressName: Value(address?.roadAddressName),
            regionName: Value(address?.regionName),
            addressResolvedAt: Value(address == null ? null : DateTime.now()),
            createdAt: visitedAt,
            updatedAt: visitedAt,
            visitCount: 0,
          ),
        );
    final cluster = await (_database.select(
      _database.placeClusters,
    )..where((row) => row.id.equals(id))).getSingle();
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

  Future<void> _resolveAddressIfMissing(PlaceCluster cluster) async {
    if (cluster.addressResolvedAt != null ||
        cluster.addressName != null ||
        cluster.roadAddressName != null ||
        cluster.regionName != null) {
      return;
    }
    final address = await _resolveAddress(
      latitude: cluster.centerLatitude,
      longitude: cluster.centerLongitude,
    );
    if (address == null) return;
    await (_database.update(_database.placeClusters)
          ..where((row) => row.id.equals(cluster.id)))
        .write(_addressCompanion(address));
  }

  Future<PlaceAddress?> _resolveAddress({
    required double latitude,
    required double longitude,
  }) async {
    try {
      return await _reverseGeocoder?.resolve(
        latitude: latitude,
        longitude: longitude,
      );
    } on Object {
      return null;
    }
  }

  PlaceClustersCompanion _addressCompanion(PlaceAddress address) {
    return PlaceClustersCompanion(
      addressName: Value(address.addressName),
      roadAddressName: Value(address.roadAddressName),
      regionName: Value(address.regionName),
      addressResolvedAt: Value(DateTime.now()),
    );
  }
}
