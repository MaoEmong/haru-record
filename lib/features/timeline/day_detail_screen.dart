import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../storage/app_database.dart';
import 'day_activity_preview_repository.dart';
import 'day_route_models.dart';
import 'day_route_repository.dart';
import 'day_timeline_models.dart';
import 'day_timeline_repository.dart';

class DayDetailScreen extends StatefulWidget {
  const DayDetailScreen({
    super.key,
    required this.database,
    required this.date,
    this.title,
    this.body,
    this.appBarTitle = '하루 자세히 보기',
    this.showRawRecords = false,
  });

  final AppDatabase database;
  final DateTime date;
  final String? title;
  final String? body;
  final String appBarTitle;
  final bool showRawRecords;

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  late Future<_DayDetailSnapshot> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = _load();
  }

  Future<_DayDetailSnapshot> _load() async {
    final timeline = await DayTimelineRepository(
      widget.database,
    ).loadForDate(widget.date);
    final route = await DayRouteRepository(
      widget.database,
    ).loadForDate(widget.date);
    final preview = await DayActivityPreviewRepository(
      widget.database,
    ).loadForDate(widget.date);
    final allPoints = await widget.database
        .select(widget.database.locationPoints)
        .get();
    final points =
        allPoints
            .where(
              (point) =>
                  !point.timestamp.isBefore(_dayStart(widget.date)) &&
                  point.timestamp.isBefore(_dayEnd(widget.date)),
            )
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return _DayDetailSnapshot(
      timeline: timeline,
      route: route,
      preview: preview,
      pointCount: points.length,
      latestPoint: points.firstOrNull,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.appBarTitle)),
      body: SafeArea(
        child: FutureBuilder<_DayDetailSnapshot>(
          future: _snapshot,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _ReflectionHeader(
                  dateLabel: _dateKey(widget.date),
                  title: widget.title,
                  body: widget.body,
                ),
                const SizedBox(height: 12),
                _RoutePreviewCard(route: data.route),
                const SizedBox(height: 12),
                if (widget.showRawRecords) ...[
                  _RawRecordsCard(
                    pointCount: data.pointCount,
                    latestPoint: data.latestPoint,
                  ),
                  const SizedBox(height: 12),
                ],
                _SummaryCard(preview: data.preview),
                const SizedBox(height: 12),
                _RouteSummaryCard(items: data.preview.timeline),
              ],
            );
          },
        ),
      ),
    );
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime _dayStart(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _dayEnd(DateTime date) =>
      _dayStart(date).add(const Duration(days: 1));
}

class _ReflectionHeader extends StatelessWidget {
  const _ReflectionHeader({
    required this.dateLabel,
    required this.title,
    required this.body,
  });

  final String dateLabel;
  final String? title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateLabel,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title ?? '하루 흐름',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(body!, style: const TextStyle(color: AppColors.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.preview});

  final DayActivityPreview preview;

  @override
  Widget build(BuildContext context) {
    final visitCount = preview.visitCount ?? 0;
    final distance = preview.totalDistanceMeters ?? 0;
    final movingMinutes = preview.movingMinutes ?? 0;
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '하루 요약',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(label: '방문 $visitCount곳'),
                _MetricChip(label: '이동 ${_distanceLabel(distance)}'),
                _MetricChip(label: '움직임 $movingMinutes분'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _distanceLabel(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }
}

class _RoutePreviewCard extends StatelessWidget {
  const _RoutePreviewCard({required this.route});

  final DayRouteSnapshot route;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(color: AppColors.surfaceAlt),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이동 경로',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '기록 지점 ${route.points.length}개',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            if (route.points.length < 2)
              const Text(
                '경로를 그릴 만큼 위치 기록이 아직 부족해요.',
                style: TextStyle(color: AppColors.muted),
              )
            else ...[
              _DayRouteMiniMap(points: route.points),
              const SizedBox(height: 12),
              Text(
                '${route.points.first.timeLabel} -> ${route.points.last.timeLabel}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayRouteMiniMap extends StatelessWidget {
  const _DayRouteMiniMap({required this.points});

  final List<DayRoutePoint> points;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey('day-route-mini-map'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.paleBlue,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: CustomPaint(
            painter: _DayRouteMiniMapPainter(points: points),
          ),
        ),
      ),
    );
  }
}

class _DayRouteMiniMapPainter extends CustomPainter {
  const _DayRouteMiniMapPainter({required this.points});

  final List<DayRoutePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final padding = size.shortestSide * 0.16;
    final bounds = Rect.fromLTWH(
      padding,
      padding,
      size.width - (padding * 2),
      size.height - (padding * 2),
    );
    final projected = _project(points, bounds);

    final shadowPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.65)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final routePaint = Paint()
      ..color = AppColors.blueGrey
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final route = Path()..moveTo(projected.first.dx, projected.first.dy);
    for (final point in projected.skip(1)) {
      route.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(route, shadowPaint);
    canvas.drawPath(route, routePaint);
    _drawEndpoint(
      canvas,
      projected.first,
      fill: AppColors.surface,
      stroke: AppColors.blueGrey,
    );
    _drawEndpoint(
      canvas,
      projected.last,
      fill: AppColors.ink,
      stroke: AppColors.surface,
    );
  }

  List<Offset> _project(List<DayRoutePoint> points, Rect bounds) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final latRange = (maxLat - minLat).abs();
    final lngRange = (maxLng - minLng).abs();
    final safeLatRange = latRange == 0 ? 1.0 : latRange;
    final safeLngRange = lngRange == 0 ? 1.0 : lngRange;

    return points.map((point) {
      final x = bounds.left + ((point.longitude - minLng) / safeLngRange) * bounds.width;
      final y = bounds.bottom - ((point.latitude - minLat) / safeLatRange) * bounds.height;
      return Offset(x, y);
    }).toList(growable: false);
  }

  void _drawEndpoint(
    Canvas canvas,
    Offset center, {
    required Color fill,
    required Color stroke,
  }) {
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      4.5,
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _DayRouteMiniMapPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _RawRecordsCard extends StatelessWidget {
  const _RawRecordsCard({required this.pointCount, required this.latestPoint});

  final int pointCount;
  final LocationPoint? latestPoint;

  @override
  Widget build(BuildContext context) {
    final latest = latestPoint;
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(color: AppColors.surfaceAlt),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '오늘 기록중인 위치',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _MetricChip(label: '위치 기록 $pointCount개'),
            const SizedBox(height: 12),
            if (latest == null)
              const Text(
                '아직 오늘 저장된 위치가 없어요.',
                style: TextStyle(color: AppColors.muted),
              )
            else ...[
              Text(
                '최근 기록 ${_timeLabel(latest.timestamp)}',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${latest.latitude.toStringAsFixed(4)}, '
                '${latest.longitude.toStringAsFixed(4)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _timeLabel(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({required this.items});

  final List<DayTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    final routeLabel = items.isEmpty
        ? '아직 흐름을 만들 기록이 없어요'
        : items.map((item) => item.placeLabel).join(' -> ');
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '장소 흐름',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              routeLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final item in items) _TimelineDetailRow(item: item),
          ],
        ),
      ),
    );
  }
}

class _TimelineDetailRow extends StatelessWidget {
  const _TimelineDetailRow({required this.item});

  final DayTimelineItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            child: Text(
              item.timeLabel,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${item.placeLabel} · ${item.durationLabel}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DayDetailSnapshot {
  const _DayDetailSnapshot({
    required this.timeline,
    required this.route,
    required this.preview,
    required this.pointCount,
    required this.latestPoint,
  });

  final List<DayTimelineItem> timeline;
  final DayRouteSnapshot route;
  final DayActivityPreview preview;
  final int pointCount;
  final LocationPoint? latestPoint;
}
