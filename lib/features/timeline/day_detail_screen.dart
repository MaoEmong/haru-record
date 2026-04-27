import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/app_theme.dart';
import '../../app/responsive_type.dart';
import '../maps/cached_map_snapshot.dart';
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
  });

  final AppDatabase database;
  final DateTime date;
  final String? title;
  final String? body;
  final String appBarTitle;

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
    return _DayDetailSnapshot(
      timeline: timeline,
      route: route,
      preview: preview,
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
              cacheExtent: 1200,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _ReflectionHeader(
                  dateLabel: _dateKey(widget.date),
                  title: widget.title,
                  body: widget.body,
                ),
                const SizedBox(height: 12),
                _SummaryCard(preview: data.preview),
                const SizedBox(height: 12),
                _RoutePreviewCard(
                  route: data.route,
                  dateKey: _dateKey(widget.date),
                ),
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
              style: TextStyle(
                fontSize: responsiveTitleFontSize(context, 20),
                fontWeight: FontWeight.w900,
              ),
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
            Text(
              '하루 요약',
              style: TextStyle(
                fontSize: responsiveTitleFontSize(context, 18),
                fontWeight: FontWeight.w800,
              ),
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
  const _RoutePreviewCard({required this.route, required this.dateKey});

  final DayRouteSnapshot route;
  final String dateKey;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(color: AppColors.surfaceAlt),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이동 경로',
              style: TextStyle(
                fontSize: responsiveTitleFontSize(context, 18),
                fontWeight: FontWeight.w800,
              ),
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
              _DayRouteMap(route: route, dateKey: dateKey),
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

class _DayRouteMap extends StatelessWidget {
  const _DayRouteMap({required this.route, required this.dateKey});

  final DayRouteSnapshot route;
  final String dateKey;

  @override
  Widget build(BuildContext context) {
    final points = route.points
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);
    final cameraPoints = [
      ...points,
      for (final visit in route.visits) LatLng(visit.latitude, visit.longitude),
    ];
    final bounds = LatLngBounds.fromPoints(cameraPoints);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        key: const ValueKey('day-route-map'),
        height: 220,
        width: double.infinity,
        child: CachedMapSnapshot(
          key: ValueKey('map-snapshot-day-route-$dateKey'),
          cacheKey:
              'day-route-v2-$dateKey-'
              '${route.points.length}-'
              '${route.visits.length}-'
              '${route.points.last.timeLabel}',
          child: FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(18),
                maxZoom: 18,
              ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.projectapp_1',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: points,
                    color: AppColors.blueGrey,
                    strokeWidth: 4,
                    borderColor: AppColors.surface,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(markers: _markers(points)),
            ],
          ),
        ),
      ),
    );
  }

  List<Marker> _markers(List<LatLng> points) {
    final markers = [
      Marker(
        point: points.first,
        width: 34,
        height: 34,
        child: const _MapEndpointMarker(
          icon: Icons.play_arrow_rounded,
          background: AppColors.surface,
          foreground: AppColors.blueGrey,
        ),
      ),
      Marker(
        point: points.last,
        width: 34,
        height: 34,
        child: const _MapEndpointMarker(
          icon: Icons.stop_rounded,
          background: AppColors.ink,
          foreground: AppColors.surface,
        ),
      ),
    ];

    for (final visit in route.visits) {
      markers.add(
        Marker(
          point: LatLng(visit.latitude, visit.longitude),
          width: 32,
          height: 32,
          child: const _MapVisitMarker(),
        ),
      );
    }

    return markers;
  }
}

class _MapEndpointMarker extends StatelessWidget {
  const _MapEndpointMarker({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3317232E),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: foreground, size: 19),
    );
  }
}

class _MapVisitMarker extends StatelessWidget {
  const _MapVisitMarker();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2417232E),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.place_rounded, color: AppColors.ink, size: 18),
    );
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
            Text(
              '장소 흐름',
              style: TextStyle(
                fontSize: responsiveTitleFontSize(context, 18),
                fontWeight: FontWeight.w800,
              ),
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
  });

  final List<DayTimelineItem> timeline;
  final DayRouteSnapshot route;
  final DayActivityPreview preview;
}
