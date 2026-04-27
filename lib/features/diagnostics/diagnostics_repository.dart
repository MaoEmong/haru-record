import '../storage/app_database.dart';
import 'diagnostics_snapshot.dart';

class DiagnosticsRepository {
  const DiagnosticsRepository(this._database);

  final AppDatabase _database;

  Future<DiagnosticsSnapshot> load() async {
    final points = await _database.select(_database.locationPoints).get();
    points.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final visits = await _database.select(_database.visits).get();
    final reflections = await _database.select(_database.insights).get();
    return DiagnosticsSnapshot(
      locationPointCount: points.length,
      visitCount: visits.length,
      reflectionCount: reflections.length,
      lastPointTimeLabel: points.isEmpty
          ? '아직 없음'
          : _dateTimeLabel(points.first.timestamp),
    );
  }

  String _dateTimeLabel(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}-$month-$day $hour:$minute';
  }
}
