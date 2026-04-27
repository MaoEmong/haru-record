import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/places/place_cluster_repository.dart';
import 'package:projectapp_1/features/places/place_address.dart';
import 'package:projectapp_1/features/storage/app_database.dart';

void main() {
  test('creates a new place cluster when no nearby cluster exists', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = PlaceClusterRepository(database);

    final match = await repository.findOrCreateForVisit(
      latitude: 37.5665,
      longitude: 126.9780,
      radiusMeters: 100,
      visitedAt: DateTime(2026, 4, 26, 9),
    );

    expect(match.cluster.id, isPositive);
    expect(match.cluster.visitCount, 0);
    expect(match.cluster.displayName, isNull);
    expect(match.isNew, isTrue);
  });

  test('reuses a nearby place cluster without duplicating the place', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = PlaceClusterRepository(database);

    final first = await repository.findOrCreateForVisit(
      latitude: 37.5665,
      longitude: 126.9780,
      radiusMeters: 100,
      visitedAt: DateTime(2026, 4, 26, 9),
    );
    final second = await repository.findOrCreateForVisit(
      latitude: 37.5666,
      longitude: 126.9781,
      radiusMeters: 100,
      visitedAt: DateTime(2026, 4, 27, 9),
    );

    final places = await database.select(database.placeClusters).get();
    expect(second.cluster.id, first.cluster.id);
    expect(second.isNew, isFalse);
    expect(places, hasLength(1));
  });

  test('stores resolved address when creating a new cluster', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = PlaceClusterRepository(
      database,
      reverseGeocoder: _FakeReverseGeocoder(
        const PlaceAddress(
          addressName: '서울 중구 태평로1가 31',
          roadAddressName: '서울 중구 세종대로 110',
          regionName: '서울 중구 태평로1가',
        ),
      ),
    );

    final match = await repository.findOrCreateForVisit(
      latitude: 37.5665,
      longitude: 126.9780,
      radiusMeters: 100,
      visitedAt: DateTime(2026, 4, 26, 9),
    );

    expect(match.cluster.roadAddressName, '서울 중구 세종대로 110');
    expect(match.cluster.addressName, '서울 중구 태평로1가 31');
    expect(match.cluster.regionName, '서울 중구 태평로1가');
    expect(match.cluster.addressResolvedAt, isNotNull);
  });
}

class _FakeReverseGeocoder implements ReverseGeocoder {
  const _FakeReverseGeocoder(this.address);

  final PlaceAddress? address;

  @override
  Future<PlaceAddress?> resolve({
    required double latitude,
    required double longitude,
  }) async {
    return address;
  }
}
