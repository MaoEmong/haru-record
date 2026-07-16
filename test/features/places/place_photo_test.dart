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

  test('setPlacePhoto copies the image and records its path', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final place = await insertPlace(database);
    final source = fakeSourcePhoto('picked.jpg');

    await setPlacePhoto(
      database,
      place,
      source,
      directoryProvider: () async => tempDir,
    );

    final updated = await (database.select(
      database.placeClusters,
    )..where((row) => row.id.equals(place.id))).getSingle();
    expect(updated.photoPath, isNotNull);
    expect(File(updated.photoPath!).existsSync(), isTrue);
    // 원본이 지워져도 복사본은 남는다.
    source.deleteSync();
    expect(File(updated.photoPath!).existsSync(), isTrue);
  });

  test('replacing a photo deletes the previous copy', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final place = await insertPlace(database);

    await setPlacePhoto(
      database,
      place,
      fakeSourcePhoto('first.jpg'),
      directoryProvider: () async => tempDir,
    );
    final first = await (database.select(
      database.placeClusters,
    )..where((row) => row.id.equals(place.id))).getSingle();

    await setPlacePhoto(
      database,
      first,
      fakeSourcePhoto('second.jpg'),
      directoryProvider: () async => tempDir,
    );
    final second = await (database.select(
      database.placeClusters,
    )..where((row) => row.id.equals(place.id))).getSingle();

    expect(second.photoPath, isNot(first.photoPath));
    expect(File(second.photoPath!).existsSync(), isTrue);
    expect(File(first.photoPath!).existsSync(), isFalse);
  });

  test('removePlacePhoto clears the path and deletes the file', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final place = await insertPlace(database);
    await setPlacePhoto(
      database,
      place,
      fakeSourcePhoto('picked.jpg'),
      directoryProvider: () async => tempDir,
    );
    final withPhoto = await (database.select(
      database.placeClusters,
    )..where((row) => row.id.equals(place.id))).getSingle();

    await removePlacePhoto(database, withPhoto);

    final cleared = await (database.select(
      database.placeClusters,
    )..where((row) => row.id.equals(place.id))).getSingle();
    expect(cleared.photoPath, isNull);
    expect(File(withPhoto.photoPath!).existsSync(), isFalse);
  });
}
