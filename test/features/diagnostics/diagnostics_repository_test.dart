import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haru_record/features/diagnostics/diagnostics_repository.dart';
import 'package:haru_record/features/storage/app_database.dart';

void main() {
  test('reports last point and stored counts', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database
        .into(database.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: DateTime(2026, 4, 27, 9),
            latitude: 37,
            longitude: 127,
            accuracy: 20,
          ),
        );

    final snapshot = await DiagnosticsRepository(database).load();

    expect(snapshot.locationPointCount, 1);
    expect(snapshot.visitCount, 0);
    expect(snapshot.reflectionCount, 0);
    expect(snapshot.lastPointTimeLabel, '2026-04-27 09:00');
  });
}
