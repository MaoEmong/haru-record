import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/date_key.dart';
import '../storage/app_database.dart';
import '../timeline/day_activity_preview_repository.dart';

final historyDaysProvider =
    FutureProvider.family<List<HistoryDay>, HistoryQuery>((ref, query) {
      return loadHistoryDays(
        query.database,
        refreshVersion: query.refreshVersion,
      );
    });

final historyDayPreviewProvider =
    FutureProvider.family<DayActivityPreview, HistoryPreviewQuery>((
      ref,
      query,
    ) {
      return DayActivityPreviewRepository(
        query.database,
      ).loadForDate(query.date);
    });

class HistoryQuery {
  const HistoryQuery({required this.database, required this.refreshVersion});

  final AppDatabase database;
  final int refreshVersion;

  @override
  bool operator ==(Object other) {
    return other is HistoryQuery &&
        identical(database, other.database) &&
        refreshVersion == other.refreshVersion;
  }

  @override
  int get hashCode => Object.hash(identityHashCode(database), refreshVersion);
}

class HistoryPreviewQuery {
  const HistoryPreviewQuery({
    required this.database,
    required this.date,
    required this.refreshVersion,
  });

  final AppDatabase database;
  final DateTime date;
  final int refreshVersion;

  @override
  bool operator ==(Object other) {
    return other is HistoryPreviewQuery &&
        identical(database, other.database) &&
        date == other.date &&
        refreshVersion == other.refreshVersion;
  }

  @override
  int get hashCode =>
      Object.hash(identityHashCode(database), date, refreshVersion);
}

class HistoryDay {
  const HistoryDay({
    required this.database,
    required this.refreshVersion,
    required this.date,
    required this.title,
    required this.preview,
    this.body,
    this.insight,
  });

  final AppDatabase database;
  final int refreshVersion;
  final DateTime date;
  final String title;
  final String? body;
  final Insight? insight;
  final Future<DayActivityPreview> preview;
}

Future<List<HistoryDay>> loadHistoryDays(
  AppDatabase database, {
  int refreshVersion = 0,
}) async {
  final insights = await database.select(database.insights).get();
  final sorted = insights..sort((a, b) => b.date.compareTo(a.date));
  final previewRepository = DayActivityPreviewRepository(database);
  final days = [
    for (final insight in sorted)
      HistoryDay(
        database: database,
        refreshVersion: refreshVersion,
        date: insight.date,
        title: insight.title,
        body: insight.body,
        insight: insight,
        preview: previewRepository.loadForDate(insight.date),
      ),
  ];

  final today = DateTime.now();
  if (!days.any((day) => isSameLocalDate(day.date, today)) &&
      await hasHistoryDataForDate(database, today)) {
    days.insert(
      0,
      HistoryDay(
        database: database,
        refreshVersion: refreshVersion,
        date: today,
        title: '오늘의 하루',
        body: '오늘 기기 안에 쌓이고 있는 위치 기록과 머문 곳을 확인해요.',
        preview: previewRepository.loadForDate(today),
      ),
    );
  }
  return days;
}

Future<bool> hasHistoryDataForDate(AppDatabase database, DateTime date) async {
  final start = DateTime(date.year, date.month, date.day);
  final end = start.add(const Duration(days: 1));
  final summaryRows =
      await (database.select(database.dailySummaries)
            ..where((row) => row.date.equals(dateKey(date)))
            ..limit(1))
          .get();
  if (summaryRows.isNotEmpty) return true;

  final visitRows =
      await (database.select(database.visits)
            ..where(
              (row) =>
                  row.startedAt.isBiggerOrEqualValue(start) &
                  row.startedAt.isSmallerThanValue(end),
            )
            ..limit(1))
          .get();
  if (visitRows.isNotEmpty) return true;

  final pointRows =
      await (database.select(database.locationPoints)
            ..where(
              (row) =>
                  row.timestamp.isBiggerOrEqualValue(start) &
                  row.timestamp.isSmallerThanValue(end),
            )
            ..limit(1))
          .get();
  return pointRows.isNotEmpty;
}
