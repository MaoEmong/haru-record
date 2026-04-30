import 'package:drift/drift.dart';

import '../core/time/date_key.dart';
import '../features/background/daily_insight_worker.dart';
import '../features/storage/app_database.dart';
import '../features/tracking/location_event_importer.dart';
import 'daily_processing_service.dart';

class StartupRecordSyncService {
  const StartupRecordSyncService({
    required AppDatabase database,
    required DailyProcessingService dailyProcessingService,
    required Future<LocationEventImportResult> Function() importPendingEvents,
  }) : _database = database,
       _dailyProcessingService = dailyProcessingService,
       _importPendingEvents = importPendingEvents;

  final AppDatabase _database;
  final DailyProcessingService _dailyProcessingService;
  final Future<LocationEventImportResult> Function() _importPendingEvents;

  Future<StartupRecordSyncResult> sync({DateTime? now}) async {
    final importResult = await _importPendingEvents();
    final effectiveNow = now ?? DateTime.now();
    DailyProcessingResult? dailyProcessingResult;
    if (await _hasUnprocessedYesterdayRecords(effectiveNow)) {
      dailyProcessingResult = await _dailyProcessingService.run(
        now: effectiveNow,
      );
    }
    return StartupRecordSyncResult(
      importResult: importResult,
      dailyProcessingResult: dailyProcessingResult,
    );
  }

  Future<bool> _hasUnprocessedYesterdayRecords(DateTime now) async {
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final summaryDateKey = dateKey(yesterdayStart);

    final existingSummary =
        await (_database.select(_database.dailySummaries)
              ..where((summary) => summary.date.equals(summaryDateKey))
              ..limit(1))
            .getSingleOrNull();
    if (existingSummary != null) return false;

    final yesterdayPoint =
        await (_database.select(_database.locationPoints)
              ..where(
                (point) =>
                    point.timestamp.isBiggerOrEqualValue(yesterdayStart) &
                    point.timestamp.isSmallerThanValue(todayStart),
              )
              ..limit(1))
            .getSingleOrNull();
    return yesterdayPoint != null;
  }
}

class StartupRecordSyncResult {
  const StartupRecordSyncResult({
    required this.importResult,
    required this.dailyProcessingResult,
  });

  final LocationEventImportResult importResult;
  final DailyProcessingResult? dailyProcessingResult;

  bool get hasChanges {
    if (importResult.importedCount > 0) return true;
    return switch (dailyProcessingResult?.outcome) {
      DailyProcessingOutcome.createdReflection ||
      DailyProcessingOutcome.noHighlights => true,
      _ => false,
    };
  }
}
