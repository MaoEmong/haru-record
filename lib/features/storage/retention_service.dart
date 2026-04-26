import 'package:drift/drift.dart';

import 'app_database.dart';

class RetentionService {
  RetentionService(this._database);

  final AppDatabase _database;

  Future<int> deleteRawPointsOlderThan(
    DateTime now, {
    required int retentionDays,
  }) {
    final cutoff = now.subtract(Duration(days: retentionDays));
    return (_database.delete(
      _database.locationPoints,
    )..where((point) => point.timestamp.isSmallerThanValue(cutoff))).go();
  }
}
