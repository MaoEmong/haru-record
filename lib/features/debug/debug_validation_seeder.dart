import 'package:drift/drift.dart';

import '../storage/app_database.dart';

class DebugValidationSeeder {
  const DebugValidationSeeder(this._database);

  final AppDatabase _database;

  Future<void> seedYesterdayVisit({DateTime? now}) async {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dayBeforeYesterday = today.subtract(const Duration(days: 2));
    final firstPoint = yesterday.add(const Duration(hours: 10));
    final secondPoint = firstPoint.add(const Duration(minutes: 11));

    await _database.transaction(() async {
      await _database
          .into(_database.dailySummaries)
          .insertOnConflictUpdate(
            DailySummariesCompanion.insert(
              date: _dateKey(dayBeforeYesterday),
              totalDistanceMeters: 1200,
              movingMinutes: 30,
              stationaryMinutes: 300,
              visitCount: 2,
              newPlaceCount: 0,
            ),
          );
      await _database
          .into(_database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: firstPoint,
              latitude: 37.5665,
              longitude: 126.9780,
              accuracy: 12,
              speed: const Value(0),
              source: const Value('debug'),
            ),
          );
      await _database
          .into(_database.locationPoints)
          .insert(
            LocationPointsCompanion.insert(
              timestamp: secondPoint,
              latitude: 37.56652,
              longitude: 126.97802,
              accuracy: 12,
              speed: const Value(0),
              source: const Value('debug'),
            ),
          );
    });
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
