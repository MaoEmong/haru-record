import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

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

/// 장소에 붙은 사진들을 오래된 순으로 불러온다.
Future<List<PlacePhoto>> loadPlacePhotos(
  AppDatabase database,
  int placeClusterId,
) {
  return (database.select(database.placePhotos)
        ..where((row) => row.placeClusterId.equals(placeClusterId))
        ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
      .get();
}

/// 장소에 사진을 추가한다. 갤러리/카메라가 준 임시 파일은 언제 지워질지
/// 모르므로 앱 문서 폴더로 복사해 보관한다. 여러 장 추가 가능.
Future<void> addPlacePhoto(
  AppDatabase database,
  PlaceCluster place,
  File source, {
  Future<Directory> Function()? directoryProvider,
}) async {
  final baseDirectory =
      await (directoryProvider ?? getApplicationDocumentsDirectory)();
  final photoDirectory = Directory('${baseDirectory.path}/place_photos');
  await photoDirectory.create(recursive: true);
  final dotIndex = source.path.lastIndexOf('.');
  final extension = dotIndex == -1 ? 'jpg' : source.path.substring(dotIndex + 1);
  final target = File(
    '${photoDirectory.path}/place_${place.id}_'
    '${DateTime.now().microsecondsSinceEpoch}.$extension',
  );
  await source.copy(target.path);
  await database
      .into(database.placePhotos)
      .insert(
        PlacePhotosCompanion.insert(
          placeClusterId: place.id,
          filePath: target.path,
          createdAt: DateTime.now(),
        ),
      );
}

/// 사진 한 장을 삭제한다. DB 행과 복사된 파일을 함께 정리한다.
Future<void> deletePlacePhoto(AppDatabase database, PlacePhoto photo) async {
  final file = File(photo.filePath);
  if (await file.exists()) await file.delete();
  await (database.delete(
    database.placePhotos,
  )..where((row) => row.id.equals(photo.id))).go();
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
