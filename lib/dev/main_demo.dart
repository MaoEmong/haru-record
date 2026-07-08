// 데모/스크린샷용 엔트리포인트.
//
// 앱 데이터베이스를 비우고 서울 시내를 오가는 며칠치 더미 기록을 채운 뒤
// 평소와 같은 앱을 실행합니다. 실제 기기에서 실행하면 기존 기록이 지워지므로
// 개발 장비에서만 사용하세요.
//
//   flutter run -d windows -t lib/dev/main_demo.dart

import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter/widgets.dart';

import '../features/storage/app_database.dart';
import '../features/storage/database_factory.dart';
import '../main.dart' as app;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase(openAppDatabaseConnection());
  await _seedDemoData(database);
  await database.close();
  await app.main();
}

const _home = (lat: 37.5423, lng: 126.9498); // 마포 쪽 주택가
const _office = (lat: 37.5660, lng: 126.9784); // 을지로 사무실
const _cafe = (lat: 37.5636, lng: 126.9838); // 을지로3가 카페
const _park = (lat: 37.5285, lng: 126.9327); // 여의도 한강공원
const _bookstore = (lat: 37.5704, lng: 126.9922); // 종로 서점 (이름 미지정)

final _random = math.Random(20260708);

Future<void> _seedDemoData(AppDatabase db) async {
  await db.delete(db.insights).go();
  await db.delete(db.dailySummaries).go();
  await db.delete(db.visits).go();
  await db.delete(db.locationPoints).go();
  await db.delete(db.placeClusters).go();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime day(int daysAgo) => today.subtract(Duration(days: daysAgo));

  final homeId = await _insertPlace(
    db,
    _home,
    name: '집',
    address: '서울 마포구 신수동',
    region: '마포구',
    visitCount: 26,
    firstSeen: day(6),
  );
  final officeId = await _insertPlace(
    db,
    _office,
    name: '회사',
    address: '서울 중구 을지로 100',
    region: '중구',
    visitCount: 21,
    firstSeen: day(6),
  );
  final cafeId = await _insertPlace(
    db,
    _cafe,
    name: '단골 카페',
    address: '서울 중구 을지로3가',
    region: '중구',
    visitCount: 9,
    firstSeen: day(5),
  );
  final parkId = await _insertPlace(
    db,
    _park,
    name: '한강공원',
    address: '서울 영등포구 여의도동',
    region: '영등포구',
    visitCount: 3,
    firstSeen: day(3),
  );
  final bookstoreId = await _insertPlace(
    db,
    _bookstore,
    address: '서울 종로구 종로2가',
    region: '종로구',
    visitCount: 1,
    firstSeen: day(1),
  );

  // ── 오늘: 집 → 회사 → 카페 → 회사 (스크린샷 시점 기준 진행 중) ──
  await _seedDay(
    db,
    date: day(0),
    stops: [
      _Stop(_home, homeId, start: 6 * 60 + 40, end: 7 * 60 + 40),
      _Stop(_office, officeId, start: 8 * 60 + 10, end: 12 * 60 + 5),
      _Stop(_cafe, cafeId, start: 12 * 60 + 15, end: 13 * 60 + 5),
      _Stop(_office, officeId, start: 13 * 60 + 15, end: 15 * 60 + 5),
    ],
    summary: _Summary(
      distanceMeters: 7600,
      movingMinutes: 55,
      stationaryMinutes: 430,
      visitCount: 4,
      newPlaceCount: 0,
      longestStayPlaceId: officeId,
    ),
  );

  // ── 어제: 퇴근 후 한강공원까지 다녀온 하루 ──
  await _seedDay(
    db,
    date: day(1),
    stops: [
      _Stop(_home, homeId, start: 6 * 60 + 30, end: 7 * 60 + 45),
      _Stop(_office, officeId, start: 8 * 60 + 15, end: 12 * 60),
      _Stop(_bookstore, bookstoreId, start: 12 * 60 + 20, end: 13 * 60),
      _Stop(_office, officeId, start: 13 * 60 + 20, end: 18 * 60 + 10),
      _Stop(_park, parkId, start: 19 * 60, end: 20 * 60 + 30),
      _Stop(_home, homeId, start: 21 * 60 + 10, end: 23 * 60 + 50),
    ],
    summary: _Summary(
      distanceMeters: 12400,
      movingMinutes: 96,
      stationaryMinutes: 700,
      visitCount: 6,
      newPlaceCount: 1,
      longestStayPlaceId: officeId,
    ),
    insight: _Insight(
      type: 'newPlace',
      severity: 'important',
      title: '새로운 곳에 다녀왔어요',
      body: '어제는 평소 다니던 길에서 벗어나 새로운 곳에 들렀어요. 저녁에는 한강공원에서 한 시간 반을 보냈네요.',
      evidence: '새롭게 보인 곳 1곳, 12.4km 이동',
    ),
  );

  // ── 그제: 평범한 출퇴근 ──
  await _seedDay(
    db,
    date: day(2),
    stops: [
      _Stop(_home, homeId, start: 6 * 60 + 50, end: 7 * 60 + 50),
      _Stop(_office, officeId, start: 8 * 60 + 20, end: 12 * 60 + 10),
      _Stop(_cafe, cafeId, start: 12 * 60 + 20, end: 13 * 60),
      _Stop(_office, officeId, start: 13 * 60 + 10, end: 18 * 60 + 20),
      _Stop(_home, homeId, start: 19 * 60, end: 23 * 60 + 50),
    ],
    summary: _Summary(
      distanceMeters: 7900,
      movingMinutes: 62,
      stationaryMinutes: 760,
      visitCount: 5,
      newPlaceCount: 0,
      longestStayPlaceId: officeId,
    ),
    insight: _Insight(
      type: 'routineTrend',
      severity: 'neutral',
      title: '평소와 비슷한 하루였어요',
      body: '집과 회사를 오가는 익숙한 흐름이었어요. 점심에는 단골 카페에 들렀네요.',
      evidence: '5곳 방문, 최근 평균 5회',
    ),
  );

  // ── 3일 전: 요약과 회고만 있는 날 ──
  await _seedDay(
    db,
    date: day(3),
    stops: [
      _Stop(_home, homeId, start: 8 * 60, end: 10 * 60 + 30),
      _Stop(_park, parkId, start: 11 * 60, end: 14 * 60 + 20),
      _Stop(_home, homeId, start: 15 * 60, end: 23 * 60 + 50),
    ],
    summary: _Summary(
      distanceMeters: 9800,
      movingMinutes: 88,
      stationaryMinutes: 830,
      visitCount: 3,
      newPlaceCount: 0,
      longestStayPlaceId: homeId,
    ),
    insight: _Insight(
      type: 'movementChange',
      severity: 'notable',
      title: '오래 걸은 하루였어요',
      body: '한강공원을 따라 평소보다 오래 걸었어요. 이동 거리가 최근 평균을 훌쩍 넘었네요.',
      evidence: '9800m, 최근 평균 7200m',
    ),
  );

  // ── 4일 전: 조용한 하루 ──
  await _seedDay(
    db,
    date: day(4),
    stops: [
      _Stop(_home, homeId, start: 9 * 60, end: 12 * 60),
      _Stop(_cafe, cafeId, start: 13 * 60, end: 15 * 60),
      _Stop(_home, homeId, start: 15 * 60 + 40, end: 23 * 60 + 50),
    ],
    summary: _Summary(
      distanceMeters: 4100,
      movingMinutes: 41,
      stationaryMinutes: 900,
      visitCount: 3,
      newPlaceCount: 0,
      longestStayPlaceId: homeId,
    ),
    insight: _Insight(
      type: 'visitChange',
      severity: 'notable',
      title: '조용히 보낸 하루였어요',
      body: '집에서 대부분의 시간을 보냈고, 오후에 잠깐 카페에 다녀왔어요.',
      evidence: '3곳 방문, 최근 평균 5회',
    ),
  );
}

class _Stop {
  const _Stop(this.place, this.placeId, {required this.start, required this.end});

  final ({double lat, double lng}) place;
  final int placeId;
  final int start; // 자정 기준 분
  final int end;
}

class _Summary {
  const _Summary({
    required this.distanceMeters,
    required this.movingMinutes,
    required this.stationaryMinutes,
    required this.visitCount,
    required this.newPlaceCount,
    this.longestStayPlaceId,
  });

  final double distanceMeters;
  final int movingMinutes;
  final int stationaryMinutes;
  final int visitCount;
  final int newPlaceCount;
  final int? longestStayPlaceId;
}

class _Insight {
  const _Insight({
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
    required this.evidence,
  });

  final String type;
  final String severity;
  final String title;
  final String body;
  final String evidence;
}

Future<int> _insertPlace(
  AppDatabase db,
  ({double lat, double lng}) place, {
  String? name,
  required String address,
  required String region,
  required int visitCount,
  required DateTime firstSeen,
}) {
  return db
      .into(db.placeClusters)
      .insert(
        PlaceClustersCompanion.insert(
          centerLatitude: place.lat,
          centerLongitude: place.lng,
          radiusMeters: 80,
          displayName: Value(name),
          addressName: Value(address),
          regionName: Value(region),
          addressResolvedAt: Value(firstSeen),
          createdAt: firstSeen,
          updatedAt: firstSeen,
          visitCount: visitCount,
        ),
      );
}

Future<void> _seedDay(
  AppDatabase db, {
  required DateTime date,
  required List<_Stop> stops,
  required _Summary summary,
  _Insight? insight,
}) async {
  DateTime at(int minutes) => date.add(Duration(minutes: minutes));

  for (var i = 0; i < stops.length; i++) {
    final stop = stops[i];

    // 머무는 동안의 좌표 (5~7분 간격, 자리 주변 흔들림)
    await _insertDwellPoints(db, stop, at);

    // 다음 장소로 이동하는 구간의 좌표 (2분 간격)
    if (i + 1 < stops.length) {
      final next = stops[i + 1];
      await _insertMovePoints(db, stop, next, at);
    }

    await db
        .into(db.visits)
        .insert(
          VisitsCompanion.insert(
            placeClusterId: Value(stop.placeId),
            startedAt: at(stop.start),
            endedAt: at(stop.end),
            durationMinutes: stop.end - stop.start,
            representativeLatitude: stop.place.lat,
            representativeLongitude: stop.place.lng,
          ),
        );
  }

  await db
      .into(db.dailySummaries)
      .insert(
        DailySummariesCompanion.insert(
          date: _dateKey(date),
          totalDistanceMeters: summary.distanceMeters,
          movingMinutes: summary.movingMinutes,
          stationaryMinutes: summary.stationaryMinutes,
          visitCount: summary.visitCount,
          newPlaceCount: summary.newPlaceCount,
          longestStayPlaceId: Value(summary.longestStayPlaceId),
        ),
      );

  if (insight != null) {
    await db
        .into(db.insights)
        .insert(
          InsightsCompanion.insert(
            date: date,
            type: insight.type,
            severity: insight.severity,
            title: insight.title,
            body: insight.body,
            evidence: insight.evidence,
            createdAt: date.add(const Duration(days: 1, hours: 2)),
          ),
        );
  }
}

Future<void> _insertDwellPoints(
  AppDatabase db,
  _Stop stop,
  DateTime Function(int) at,
) async {
  for (var minute = stop.start; minute <= stop.end; minute += 5 + _random.nextInt(3)) {
    await db
        .into(db.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: at(minute),
            latitude: stop.place.lat + _jitter(25),
            longitude: stop.place.lng + _jitter(25),
            accuracy: 8 + _random.nextDouble() * 14,
            speed: const Value(0.2),
          ),
        );
  }
}

Future<void> _insertMovePoints(
  AppDatabase db,
  _Stop from,
  _Stop to,
  DateTime Function(int) at,
) async {
  final start = from.end;
  final end = to.start;
  final span = end - start;
  if (span <= 0) return;
  for (var minute = start + 1; minute < end; minute += 2) {
    final t = (minute - start) / span;
    await db
        .into(db.locationPoints)
        .insert(
          LocationPointsCompanion.insert(
            timestamp: at(minute),
            latitude: _lerp(from.place.lat, to.place.lat, t) + _jitter(30),
            longitude: _lerp(from.place.lng, to.place.lng, t) + _jitter(30),
            accuracy: 10 + _random.nextDouble() * 20,
            speed: Value(1.2 + _random.nextDouble() * 2),
          ),
        );
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

// meters를 대략의 위경도 오프셋으로 변환한 랜덤 흔들림
double _jitter(double meters) =>
    (_random.nextDouble() * 2 - 1) * meters / 111000;

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
