import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as timezone;
import 'package:workmanager/workmanager.dart';

import '../../core/config/env_config.dart';
import '../../core/geo/geo_math.dart';
import '../../core/logging/app_logger.dart';
import '../../core/time/date_key.dart';
import '../../core/time/local_timezone.dart';
import '../analysis/daily_summary_service.dart';
import '../insights/insight_generation_service.dart';
import '../insights/insight_models.dart';
import '../insights/pattern_analysis_service.dart';
import '../notifications/notification_service.dart';
import '../places/place_clustering_service.dart';
import '../places/place_cluster_repository.dart';
import '../processing/location_post_processor.dart';
import '../settings/settings_models.dart';
import '../settings/settings_repository.dart';
import '../storage/app_database.dart';
import '../storage/database_factory.dart';
import '../storage/retention_service.dart';
import '../tracking/location_event_importer.dart';

const dailyInsightWorkerName = 'dailyInsightWorker';

enum DailyProcessingOutcome {
  createdReflection,
  noRawRecords,
  noYesterdayRecords,
  noHighlights,
}

class DailyProcessingResult {
  const DailyProcessingResult({
    required this.outcome,
    required this.totalPointCount,
    required this.yesterdayPointCount,
    required this.createdReflectionCount,
  });

  final DailyProcessingOutcome outcome;
  final int totalPointCount;
  final int yesterdayPointCount;
  final int createdReflectionCount;
}

abstract interface class DailyWorkerScheduler {
  Future<void> initialize(void Function() dispatcher);

  Future<void> registerPeriodicTask({
    required String uniqueName,
    required String taskName,
    required Duration frequency,
  });
}

class WorkmanagerDailyWorkerScheduler implements DailyWorkerScheduler {
  WorkmanagerDailyWorkerScheduler({Workmanager? workmanager})
    : _workmanager = workmanager ?? Workmanager();

  final Workmanager _workmanager;

  @override
  Future<void> initialize(void Function() dispatcher) {
    return _workmanager.initialize(dispatcher);
  }

  @override
  Future<void> registerPeriodicTask({
    required String uniqueName,
    required String taskName,
    required Duration frequency,
  }) {
    return _workmanager.registerPeriodicTask(
      uniqueName,
      taskName,
      frequency: frequency,
    );
  }
}

class DailyInsightProcessor {
  DailyInsightProcessor({
    required AppDatabase database,
    required NotificationService notificationService,
    required Future<LocationEventImportResult> Function() importPendingEvents,
    required AppSettings settings,
    PlaceClusteringService? placeClusteringService,
    PlaceClusterRepository? placeClusterRepository,
    DailySummaryService? dailySummaryService,
    InsightGenerationService? insightGenerationService,
    PatternAnalysisService? patternAnalysisService,
    RetentionService? retentionService,
  }) : _database = database,
       _notificationService = notificationService,
       _importPendingEvents = importPendingEvents,
       _settings = settings,
       _placeClusteringService =
           placeClusteringService ??
           PlaceClusteringService(
             clusterRadiusMeters: settings.minimumMovementMeters.toDouble(),
             minimumStayMinutes: settings.minimumStayMinutes,
           ),
       _placeClusterRepository =
           placeClusterRepository ?? PlaceClusterRepository(database),
       _dailySummaryService = dailySummaryService ?? DailySummaryService(),
       _insightGenerationService =
           insightGenerationService ?? InsightGenerationService(),
       _patternAnalysisService =
           patternAnalysisService ?? const PatternAnalysisService(),
       _retentionService = retentionService ?? RetentionService(database);

  final AppDatabase _database;
  final NotificationService _notificationService;
  final Future<LocationEventImportResult> Function() _importPendingEvents;
  final AppSettings _settings;
  final PlaceClusteringService _placeClusteringService;
  final PlaceClusterRepository _placeClusterRepository;
  final DailySummaryService _dailySummaryService;
  final InsightGenerationService _insightGenerationService;
  final PatternAnalysisService _patternAnalysisService;
  final RetentionService _retentionService;

  Future<DailyProcessingResult> run({required DateTime now}) async {
    await _importPendingEvents();

    final yesterday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    final totalPointCount = await _countLocationPoints();
    final baseline = await _recentBaseline(before: yesterday);
    final points = await _loadLocationPointsFor(yesterday);
    final visitDetectionPoints = await _loadLocationPointsForVisitDetection(
      yesterday,
      points,
    );
    if (totalPointCount == 0) {
      await _finishRetentionAndNotifications(now);
      return const DailyProcessingResult(
        outcome: DailyProcessingOutcome.noRawRecords,
        totalPointCount: 0,
        yesterdayPointCount: 0,
        createdReflectionCount: 0,
      );
    }

    if (points.isEmpty) {
      await _finishRetentionAndNotifications(now);
      return DailyProcessingResult(
        outcome: DailyProcessingOutcome.noYesterdayRecords,
        totalPointCount: totalPointCount,
        yesterdayPointCount: 0,
        createdReflectionCount: 0,
      );
    }

    final visits = const LocationPostProcessor().detectVisits(
      points: visitDetectionPoints,
      settings: _settings,
      clusteringService: _placeClusteringService,
    );

    final persistedVisits = <_PersistableVisit>[];
    for (final visit in visits) {
      final clippedVisit = _clipVisitToDate(visit, yesterday);
      if (clippedVisit == null) continue;

      final match = await _placeClusterRepository.findOrCreateForVisit(
        latitude: clippedVisit.latitude,
        longitude: clippedVisit.longitude,
        radiusMeters: _settings.minimumMovementMeters.toDouble(),
        visitedAt: clippedVisit.startedAt,
      );
      final hasEarlierVisit = await _hasEarlierVisitForPlace(
        placeClusterId: match.cluster.id,
        before: yesterday,
      );
      persistedVisits.add(
        _PersistableVisit(
          visit: clippedVisit,
          placeClusterId: match.cluster.id,
          isNewPlace: !hasEarlierVisit,
        ),
      );
    }

    final mergedVisits = _mergeAdjacentVisitsForSamePlace(persistedVisits);
    final visitSnapshots = <VisitSnapshot>[];
    DetectedVisit? previousVisit;
    for (final item in mergedVisits) {
      final visit = item.visit;
      visitSnapshots.add(
        VisitSnapshot(
          durationMinutes: visit.durationMinutes,
          distanceFromPreviousMeters: previousVisit == null
              ? 0
              : distanceMeters(
                  previousVisit.latitude,
                  previousVisit.longitude,
                  visit.latitude,
                  visit.longitude,
                ),
          isNewPlace: item.isNewPlace,
          placeClusterId: item.placeClusterId,
        ),
      );
      previousVisit = visit;
    }

    final summary = _dailySummaryService.buildSummary(
      date: yesterday,
      visits: visitSnapshots,
    );

    final recentAverage = baseline ?? _baselineFromSummary(summary);
    final patternSignals = _patternAnalysisService.analyze([
      ...await _recentSummaries(before: yesterday),
      summary,
    ]);
    final insights = _insightGenerationService.generate(
      yesterday: summary,
      recentAverage: recentAverage,
      patternSignals: patternSignals,
    );
    await _replaceDailyOutputs(yesterday, mergedVisits, summary, insights);
    await _placeClusterRepository.recalculateVisitCounts();
    await _finishRetentionAndNotifications(now, insights: insights);

    return DailyProcessingResult(
      outcome: insights.isEmpty
          ? DailyProcessingOutcome.noHighlights
          : DailyProcessingOutcome.createdReflection,
      totalPointCount: totalPointCount,
      yesterdayPointCount: points.length,
      createdReflectionCount: insights.length,
    );
  }

  Future<void> _finishRetentionAndNotifications(
    DateTime now, {
    List<GeneratedInsight> insights = const [],
  }) async {
    await _retentionService.deleteRawPointsOlderThan(
      now,
      retentionDays: _settings.rawPointRetentionDays,
    );

    if (_settings.notificationEnabled) {
      final leadInsight = insights.firstOrNull;
      await _notificationService.scheduleDailyInsight(
        hour: _settings.notificationHour,
        minute: _settings.notificationMinute,
        title: leadInsight?.title,
        body: leadInsight?.body,
      );
    } else {
      await _notificationService.cancelDailyInsight();
    }
  }

  Future<int> _countLocationPoints() async {
    final points = await _database.select(_database.locationPoints).get();
    return points.length;
  }

  Future<List<LocationPoint>> _loadLocationPointsFor(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final query = _database.select(_database.locationPoints)
      ..where(
        (point) =>
            point.timestamp.isBiggerOrEqualValue(start) &
            point.timestamp.isSmallerThanValue(end),
      );
    return await query.get()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<List<LocationPoint>> _loadLocationPointsForVisitDetection(
    DateTime date,
    List<LocationPoint> points,
  ) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final nextPointQuery = _database.select(_database.locationPoints)
      ..where((point) => point.timestamp.isBiggerOrEqualValue(end))
      ..orderBy([(point) => OrderingTerm.asc(point.timestamp)])
      ..limit(1);
    final nextPoint = await nextPointQuery.getSingleOrNull();
    if (nextPoint == null) return points;

    return [...points, nextPoint]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  DetectedVisit? _clipVisitToDate(DetectedVisit visit, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final clippedStart = visit.startedAt.isBefore(start)
        ? start
        : visit.startedAt;
    final clippedEnd = visit.endedAt.isAfter(end) ? end : visit.endedAt;
    if (!clippedEnd.isAfter(clippedStart)) return null;

    return DetectedVisit(
      startedAt: clippedStart,
      endedAt: clippedEnd,
      durationMinutes: clippedEnd.difference(clippedStart).inMinutes,
      latitude: visit.latitude,
      longitude: visit.longitude,
    );
  }

  List<_PersistableVisit> _mergeAdjacentVisitsForSamePlace(
    List<_PersistableVisit> visits,
  ) {
    if (visits.length < 2) return visits;

    final merged = <_PersistableVisit>[];
    for (final item in visits) {
      final previous = merged.isEmpty ? null : merged.last;
      if (previous != null && _canMergeVisit(previous, item)) {
        merged[merged.length - 1] = _mergeVisits(previous, item);
      } else {
        merged.add(item);
      }
    }
    return merged;
  }

  bool _canMergeVisit(_PersistableVisit previous, _PersistableVisit current) {
    if (previous.placeClusterId != current.placeClusterId) return false;
    final gap = current.visit.startedAt.difference(previous.visit.endedAt);
    return !gap.isNegative && gap <= _maximumSamePlaceFragmentGap;
  }

  _PersistableVisit _mergeVisits(
    _PersistableVisit previous,
    _PersistableVisit current,
  ) {
    final first = previous.visit;
    final second = current.visit;
    final totalDuration = first.durationMinutes + second.durationMinutes;
    final latitude = totalDuration == 0
        ? first.latitude
        : ((first.latitude * first.durationMinutes) +
                  (second.latitude * second.durationMinutes)) /
              totalDuration;
    final longitude = totalDuration == 0
        ? first.longitude
        : ((first.longitude * first.durationMinutes) +
                  (second.longitude * second.durationMinutes)) /
              totalDuration;

    return _PersistableVisit(
      visit: DetectedVisit(
        startedAt: first.startedAt,
        endedAt: second.endedAt,
        durationMinutes: second.endedAt.difference(first.startedAt).inMinutes,
        latitude: latitude,
        longitude: longitude,
      ),
      placeClusterId: previous.placeClusterId,
      isNewPlace: previous.isNewPlace || current.isNewPlace,
    );
  }

  Future<bool> _hasEarlierVisitForPlace({
    required int placeClusterId,
    required DateTime before,
  }) async {
    final start = DateTime(before.year, before.month, before.day);
    final query = _database.select(_database.visits)
      ..where(
        (visit) =>
            visit.placeClusterId.equals(placeClusterId) &
            visit.startedAt.isSmallerThanValue(start),
      );
    final visits = await query.get();
    return visits.isNotEmpty;
  }

  Future<void> _replaceDailyOutputs(
    DateTime date,
    List<_PersistableVisit> visits,
    DailySummarySnapshot summary,
    List<GeneratedInsight> insights,
  ) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final summaryDateKey = dateKey(date);
    await _database.transaction(() async {
      await (_database.delete(_database.visits)..where(
            (visit) =>
                visit.startedAt.isBiggerOrEqualValue(start) &
                visit.startedAt.isSmallerThanValue(end),
          ))
          .go();
      await (_database.delete(_database.insights)..where(
            (insight) =>
                insight.date.isBiggerOrEqualValue(start) &
                insight.date.isSmallerThanValue(end),
          ))
          .go();
      await (_database.delete(
        _database.dailySummaries,
      )..where((summary) => summary.date.equals(summaryDateKey))).go();
      for (final item in visits) {
        final visit = item.visit;
        await _database
            .into(_database.visits)
            .insert(
              VisitsCompanion.insert(
                placeClusterId: Value(item.placeClusterId),
                startedAt: visit.startedAt,
                endedAt: visit.endedAt,
                durationMinutes: visit.durationMinutes,
                representativeLatitude: visit.latitude,
                representativeLongitude: visit.longitude,
              ),
            );
      }
      await _insertDailySummary(summary);
      await _insertInsights(summary.date, insights);
    });
  }

  Future<DailySummaryBaseline?> _recentBaseline({
    required DateTime before,
  }) async {
    final summaries = await _database.select(_database.dailySummaries).get();
    final start = before.subtract(const Duration(days: 7));
    final candidates = summaries.where((summary) {
      final date = DateTime.parse(summary.date);
      return date.isBefore(before) && !date.isBefore(start);
    }).toList();
    if (candidates.isEmpty) return null;

    return DailySummaryBaseline(
      totalDistanceMeters:
          candidates.fold<double>(
            0,
            (total, summary) => total + summary.totalDistanceMeters,
          ) /
          candidates.length,
      movingMinutes:
          (candidates.fold<int>(
                    0,
                    (total, summary) => total + summary.movingMinutes,
                  ) /
                  candidates.length)
              .round(),
      visitCount:
          (candidates.fold<int>(
                    0,
                    (total, summary) => total + summary.visitCount,
                  ) /
                  candidates.length)
              .round(),
    );
  }

  Future<List<DailySummarySnapshot>> _recentSummaries({
    required DateTime before,
  }) async {
    final summaries = await _database.select(_database.dailySummaries).get();
    final start = before.subtract(const Duration(days: 7));
    final candidates = summaries
        .where((summary) {
          final date = DateTime.parse(summary.date);
          return date.isBefore(before) && !date.isBefore(start);
        })
        .map(_summarySnapshotFromRow)
        .toList();
    candidates.sort((a, b) => a.date.compareTo(b.date));
    return candidates;
  }

  DailySummarySnapshot _summarySnapshotFromRow(DailySummary row) {
    return DailySummarySnapshot(
      date: DateTime.parse(row.date),
      totalDistanceMeters: row.totalDistanceMeters,
      movingMinutes: row.movingMinutes,
      stationaryMinutes: row.stationaryMinutes,
      visitCount: row.visitCount,
      newPlaceCount: row.newPlaceCount,
      longestStayPlaceId: row.longestStayPlaceId,
    );
  }

  DailySummaryBaseline _baselineFromSummary(DailySummarySnapshot summary) {
    return DailySummaryBaseline(
      totalDistanceMeters: summary.totalDistanceMeters,
      movingMinutes: summary.movingMinutes,
      visitCount: summary.visitCount,
    );
  }

  Future<void> _insertDailySummary(DailySummarySnapshot summary) async {
    final date = dateKey(summary.date);
    await _database
        .into(_database.dailySummaries)
        .insert(
          DailySummariesCompanion.insert(
            date: date,
            totalDistanceMeters: summary.totalDistanceMeters,
            movingMinutes: summary.movingMinutes,
            stationaryMinutes: summary.stationaryMinutes,
            visitCount: summary.visitCount,
            newPlaceCount: summary.newPlaceCount,
            longestStayPlaceId: Value(summary.longestStayPlaceId),
          ),
        );
  }

  Future<void> _insertInsights(
    DateTime date,
    List<GeneratedInsight> insights,
  ) async {
    final createdAt = DateTime.now();
    for (final insight in insights) {
      await _database
          .into(_database.insights)
          .insert(
            InsightsCompanion.insert(
              date: date,
              type: _enumName(insight.type),
              severity: _enumName(insight.severity),
              title: insight.title,
              body: insight.body,
              evidence: insight.evidence,
              createdAt: createdAt,
            ),
          );
    }
  }

  String _enumName(Object value) => value.toString().split('.').last;
}

class _PersistableVisit {
  const _PersistableVisit({
    required this.visit,
    required this.placeClusterId,
    required this.isNewPlace,
  });

  final DetectedVisit visit;
  final int placeClusterId;
  final bool isNewPlace;
}

const Duration _maximumSamePlaceFragmentGap = Duration(minutes: 30);

Future<void> initializeDailyInsightWorker({
  DailyWorkerScheduler? scheduler,
}) async {
  final workerScheduler = scheduler ?? WorkmanagerDailyWorkerScheduler();
  await workerScheduler.initialize(dailyInsightWorkerDispatcher);
  await workerScheduler.registerPeriodicTask(
    uniqueName: dailyInsightWorkerName,
    taskName: dailyInsightWorkerName,
    frequency: const Duration(hours: 24),
  );
}

@pragma('vm:entry-point')
void dailyInsightWorkerDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await EnvConfig.load();
    await configureLocalTimezone();
    if (taskName != dailyInsightWorkerName) return true;

    final database = AppDatabase(openAppDatabaseConnection());
    try {
      final settings = await SettingsRepository().load();
      final eventDirectory = await getApplicationSupportDirectory();
      final importer = LocationEventImporter.fromFile(
        database,
        File(path.join(eventDirectory.path, 'location_events.jsonl')),
      );
      final notificationAdapter = FlutterLocalNotificationAdapter(
        location: timezone.local,
      );
      final processor = DailyInsightProcessor(
        database: database,
        notificationService: NotificationService(notificationAdapter),
        importPendingEvents: importer.importPendingEvents,
        settings: settings,
      );
      await processor.run(now: DateTime.now());
      return true;
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Daily insight worker failed.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      await database.close();
    }
  });
}
