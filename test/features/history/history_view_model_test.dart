import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haru_record/features/history/history_view_model.dart';
import 'package:haru_record/features/storage/app_database.dart';

void main() {
  Future<int> insertInsight(
    AppDatabase database, {
    required DateTime date,
    required String title,
  }) {
    return database
        .into(database.insights)
        .insert(
          InsightsCompanion.insert(
            date: date,
            type: 'movementChange',
            severity: 'notable',
            title: title,
            body: '본문',
            evidence: '근거',
            createdAt: date.add(const Duration(hours: 6)),
          ),
        );
  }

  test('shows one history entry per date even with multiple insights', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final date = DateTime(2026, 7, 14);

    await insertInsight(database, date: date, title: '가장 강한 인사이트');
    await insertInsight(database, date: date, title: '두 번째 인사이트');

    final days = await loadHistoryDays(database);
    await Future.wait(days.map((day) => day.preview));

    expect(days, hasLength(1));
    expect(days.single.date, date);
    expect(days.single.title, '가장 강한 인사이트');
  });

  test('keeps one entry per date across multiple days, newest first', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final earlier = DateTime(2026, 7, 13);
    final later = DateTime(2026, 7, 14);

    await insertInsight(database, date: earlier, title: '13일 인사이트');
    await insertInsight(database, date: later, title: '14일 인사이트');
    await insertInsight(database, date: later, title: '14일 두 번째 인사이트');

    final days = await loadHistoryDays(database);
    await Future.wait(days.map((day) => day.preview));

    expect(days, hasLength(2));
    expect(days[0].date, later);
    expect(days[0].title, '14일 인사이트');
    expect(days[1].date, earlier);
    expect(days[1].title, '13일 인사이트');
  });
}
