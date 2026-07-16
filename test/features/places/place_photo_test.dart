import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haru_record/features/places/place_management_view_model.dart';
import 'package:haru_record/features/storage/app_database.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('place_photo_test');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  Future<PlaceCluster> insertPlace(AppDatabase database) async {
    final id = await database
        .into(database.placeClusters)
        .insert(
          PlaceClustersCompanion.insert(
            centerLatitude: 34.7025,
            centerLongitude: 135.4959,
            radiusMeters: 50,
            createdAt: DateTime(2026, 7, 17),
            updatedAt: DateTime(2026, 7, 17),
            visitCount: 1,
          ),
        );
    return (database.select(
      database.placeClusters,
    )..where((row) => row.id.equals(id))).getSingle();
  }

  File fakeSourcePhoto(String name) {
    final file = File('${tempDir.path}/$name');
    file.writeAsBytesSync([1, 2, 3, 4]);
    return file;
  }

  test('a place can hold multiple photos', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final place = await insertPlace(database);

    await addPlacePhoto(
      database,
      place,
      fakeSourcePhoto('first.jpg'),
      directoryProvider: () async => tempDir,
    );
    await addPlacePhoto(
      database,
      place,
      fakeSourcePhoto('second.jpg'),
      directoryProvider: () async => tempDir,
    );

    final photos = await loadPlacePhotos(database, place.id);
    expect(photos, hasLength(2));
    for (final photo in photos) {
      expect(File(photo.filePath).existsSync(), isTrue);
    }
    // 두 장이 서로 다른 파일로 복사되어야 한다.
    expect(photos[0].filePath, isNot(photos[1].filePath));
  });

  test('copies survive after the picker source is deleted', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final place = await insertPlace(database);
    final source = fakeSourcePhoto('picked.jpg');

    await addPlacePhoto(
      database,
      place,
      source,
      directoryProvider: () async => tempDir,
    );
    source.deleteSync();

    final photos = await loadPlacePhotos(database, place.id);
    expect(File(photos.single.filePath).existsSync(), isTrue);
  });

  test('deleting one photo keeps the others intact', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final place = await insertPlace(database);
    await addPlacePhoto(
      database,
      place,
      fakeSourcePhoto('first.jpg'),
      directoryProvider: () async => tempDir,
    );
    await addPlacePhoto(
      database,
      place,
      fakeSourcePhoto('second.jpg'),
      directoryProvider: () async => tempDir,
    );
    final photos = await loadPlacePhotos(database, place.id);

    await deletePlacePhoto(database, photos.first);

    final remaining = await loadPlacePhotos(database, place.id);
    expect(remaining, hasLength(1));
    expect(remaining.single.id, photos.last.id);
    expect(File(photos.first.filePath).existsSync(), isFalse);
    expect(File(remaining.single.filePath).existsSync(), isTrue);
  });
}
