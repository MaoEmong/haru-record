import 'app_database.dart';

class AppMaintenanceService {
  const AppMaintenanceService(this._database);

  final AppDatabase _database;

  Future<void> deleteRawLocationPoints() async {
    await _database.delete(_database.locationPoints).go();
  }

  Future<void> deleteAllLocalData() async {
    await _database.transaction(() async {
      await _database.delete(_database.insights).go();
      await _database.delete(_database.dailySummaries).go();
      await _database.delete(_database.visits).go();
      await _database.delete(_database.placeClusters).go();
      await _database.delete(_database.locationPoints).go();
    });
  }
}
