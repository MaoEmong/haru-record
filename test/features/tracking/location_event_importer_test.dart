import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haru_record/features/storage/app_database.dart';
import 'package:haru_record/features/tracking/location_event_importer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('daily_pattern/tracking');
  late Directory tempDirectory;
  late File eventFile;
  late AppDatabase database;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('location_events_');
    eventFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}events.jsonl',
    );
    database = AppDatabase(NativeDatabase.memory());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getEventFilePath') {
            return eventFile.path;
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await database.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('imports valid JSONL events and truncates the native event file', () async {
    await eventFile.writeAsString(
      '{"timestamp":"2026-04-25T10:00:00.000","latitude":37.5665,"longitude":126.978,"accuracy":20,"speed":1.5,"isMock":false,"source":"android"}\n'
      '{"timestamp":"2026-04-25T10:10:00.000","latitude":37.567,"longitude":126.979,"accuracy":25}\n',
    );
    final importer = LocationEventImporter(database, channel: channel);

    final result = await importer.importPendingEvents();

    final points = await database.select(database.locationPoints).get();
    expect(result.importedCount, 2);
    expect(result.skippedCount, 0);
    expect(points, hasLength(2));
    expect(points.first.latitude, 37.5665);
    expect(points.first.speed, 1.5);
    expect(points.last.source, 'android');
    expect(await eventFile.readAsString(), isEmpty);
  });

  test('skips malformed lines while importing valid events', () async {
    await eventFile.writeAsString(
      'not-json\n'
      '{"timestamp":"2026-04-25T10:00:00.000","latitude":37.5665,"longitude":126.978,"accuracy":20}\n',
    );
    final importer = LocationEventImporter(database, channel: channel);

    final result = await importer.importPendingEvents();

    final points = await database.select(database.locationPoints).get();
    expect(result.importedCount, 1);
    expect(result.skippedCount, 1);
    expect(points, hasLength(1));
    expect(await eventFile.readAsString(), isEmpty);
  });

  test('skips non-finite or out-of-range coordinates', () async {
    await eventFile.writeAsString(
      '{"timestamp":"2026-04-25T10:00:00.000","latitude":91,"longitude":126.978,"accuracy":20}\n'
      '{"timestamp":"2026-04-25T10:01:00.000","latitude":37.5665,"longitude":181,"accuracy":20}\n'
      '{"timestamp":"2026-04-25T10:02:00.000","latitude":37.5665,"longitude":126.978,"accuracy":-1}\n'
      '{"timestamp":"2026-04-25T10:03:00.000","latitude":37.5665,"longitude":126.978,"accuracy":20}\n',
    );
    final importer = LocationEventImporter(database, channel: channel);

    final result = await importer.importPendingEvents();

    final points = await database.select(database.locationPoints).get();
    expect(result.importedCount, 1);
    expect(result.skippedCount, 3);
    expect(points.single.latitude, 37.5665);
  });

  test('keeps nearby points far enough apart to prove a stay', () async {
    await eventFile.writeAsString(
      '{"timestamp":"2026-04-25T10:00:00.000","latitude":37.5665,"longitude":126.978,"accuracy":15,"source":"android"}\n'
      '{"timestamp":"2026-04-25T10:05:00.000","latitude":37.56651,"longitude":126.97801,"accuracy":18,"source":"android"}\n'
      '{"timestamp":"2026-04-25T10:05:20.000","latitude":37.56651,"longitude":126.97801,"accuracy":18,"source":"android"}\n',
    );
    final importer = LocationEventImporter(database, channel: channel);

    final result = await importer.importPendingEvents();

    final points = await database.select(database.locationPoints).get();
    expect(result.importedCount, 3);
    expect(points, hasLength(3));
    expect(points.first.timestamp, DateTime(2026, 4, 25, 10));
    expect(points.last.timestamp, DateTime(2026, 4, 25, 10, 5, 20));
  });

  test('keeps dense walking points for route display', () async {
    await eventFile.writeAsString(
      '{"timestamp":"2026-04-25T10:00:00.000","latitude":37.5665,"longitude":126.978,"accuracy":15,"source":"android"}\n'
      '{"timestamp":"2026-04-25T10:00:10.000","latitude":37.5666,"longitude":126.978,"accuracy":15,"source":"android"}\n'
      '{"timestamp":"2026-04-25T10:00:20.000","latitude":37.5667,"longitude":126.978,"accuracy":15,"source":"android"}\n',
    );
    final importer = LocationEventImporter(database, channel: channel);

    final result = await importer.importPendingEvents();

    final points = await database.select(database.locationPoints).get();
    expect(result.importedCount, 3);
    expect(points, hasLength(3));
  });

  test('preserves events appended after the import snapshot is taken', () async {
    await eventFile.writeAsString(
      '{"timestamp":"2026-04-25T10:00:00.000","latitude":37.5665,"longitude":126.978,"accuracy":20}\n',
    );
    final importer = LocationEventImporter(
      database,
      channel: channel,
      afterSnapshot: () async {
        await eventFile.writeAsString(
          '{"timestamp":"2026-04-25T10:10:00.000","latitude":37.567,"longitude":126.979,"accuracy":25}\n',
        );
      },
    );

    final result = await importer.importPendingEvents();

    final points = await database.select(database.locationPoints).get();
    expect(result.importedCount, 1);
    expect(points, hasLength(1));
    expect(await eventFile.readAsString(), contains('2026-04-25T10:10:00.000'));
  });

  test('preserves snapshot when storage insert fails', () async {
    await eventFile.writeAsString(
      '{"timestamp":"2026-04-25T10:00:00.000","latitude":37.5665,"longitude":126.978,"accuracy":20}\n',
    );
    await database.customStatement('''
CREATE TRIGGER fail_location_insert
BEFORE INSERT ON location_points
BEGIN
  SELECT RAISE(FAIL, 'insert fail');
END;
''');
    final importer = LocationEventImporter(database, channel: channel);

    await expectLater(importer.importPendingEvents(), throwsA(anything));

    final snapshot = File('${eventFile.path}.importing');
    expect(await snapshot.exists(), isTrue);
    expect(await snapshot.readAsString(), contains('2026-04-25T10:00:00.000'));
  });

  test('does not duplicate events from a leftover import snapshot', () async {
    final snapshot = File('${eventFile.path}.importing');
    await snapshot.writeAsString(
      '{"timestamp":"2026-04-25T10:00:00.000","latitude":37.5665,"longitude":126.978,"accuracy":20,"source":"android"}\n',
    );
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 25, 10),
            latitude: 37.5665,
            longitude: 126.978,
            accuracy: 20,
          ),
        );
    final importer = LocationEventImporter(database, channel: channel);

    final result = await importer.importPendingEvents();

    final points = await database.select(database.locationPoints).get();
    expect(result.importedCount, 0);
    expect(points, hasLength(1));
    expect(await snapshot.exists(), isFalse);
  });
}
