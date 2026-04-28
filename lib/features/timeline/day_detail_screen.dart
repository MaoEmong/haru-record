import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';

import '../../app/app_theme.dart';
import '../../app/responsive_type.dart';
import '../../core/geo/coordinate_validation.dart';
import '../places/place_cluster_repository.dart';
import '../places/place_map_preview.dart';
import '../settings/settings_repository.dart';
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
    this.settingsRepository,
    this.title,
    this.body,
    this.appBarTitle = '하루 자세히 보기',
  });

  final AppDatabase database;
  final DateTime date;
  final SettingsRepository? settingsRepository;
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
    final settings = await (widget.settingsRepository ?? SettingsRepository())
        .load();
    final preview = await DayActivityPreviewRepository(
      widget.database,
    ).loadForDate(widget.date, settings: settings);
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
                _RouteSummaryCard(
                  items: data.preview.timeline,
                  onSavePlace: _saveTimelinePlace,
                ),
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

  Future<void> _saveTimelinePlace(DayTimelineItem item) async {
    if (!item.canSaveAsPlace) return;

    final name = await showDialog<String>(
      context: context,
      builder: (context) => _SavePlaceDialog(item: item),
    );
    if (name == null) return;

    final repository = PlaceClusterRepository(widget.database);
    final match = await repository.findOrCreateForVisit(
      latitude: item.latitude!,
      longitude: item.longitude!,
      radiusMeters: 80,
      visitedAt: item.startedAt!,
    );
    final normalizedName = name.trim();
    if (normalizedName.isNotEmpty || match.isNew) {
      await (widget.database.update(
        widget.database.placeClusters,
      )..where((row) => row.id.equals(match.cluster.id))).write(
        PlaceClustersCompanion(
          displayName: Value(
            normalizedName.isEmpty ? '이름 없는 장소' : normalizedName,
          ),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
    await widget.database
        .into(widget.database.visits)
        .insert(
          VisitsCompanion.insert(
            placeClusterId: Value(match.cluster.id),
            startedAt: item.startedAt!,
            endedAt: item.endedAt!,
            durationMinutes: item.durationMinutes!,
            representativeLatitude: item.latitude!,
            representativeLongitude: item.longitude!,
          ),
        );
    await repository.recalculateVisitCounts();

    if (!mounted) return;
    setState(() {
      _snapshot = _load();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('방문한 곳에 저장했어요')));
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
              '지도 핀 ${_routeMarkerCount(route)}개',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            if (route.points.length < 2)
              const Text(
                '경로를 그릴 만큼 위치 기록이 아직 부족해요.',
                style: TextStyle(color: AppColors.muted),
              )
            else ...[
              _DayRouteMap(route: route),
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

class _DayRouteMap extends StatefulWidget {
  const _DayRouteMap({required this.route});

  final DayRouteSnapshot route;

  @override
  State<_DayRouteMap> createState() => _DayRouteMapState();
}

class _DayRouteMapState extends State<_DayRouteMap> {
  final _mapController = MapController();

  void _focusPoint(LatLng point) {
    if (!isValidCoordinate(point.latitude, point.longitude)) return;
    final currentZoom = _mapController.camera.zoom;
    final targetZoom = currentZoom < _focusedRouteZoom
        ? _focusedRouteZoom
        : currentZoom + 1;
    _mapController.move(
      point,
      targetZoom.clamp(_minimumRouteZoom, _maximumRouteZoom).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.route.points
        .where((point) => isValidCoordinate(point.latitude, point.longitude))
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);
    if (points.length < 2) {
      return const Text(
        '경로를 그릴 만큼 위치 기록이 아직 부족해요.',
        style: TextStyle(color: AppColors.muted),
      );
    }
    final cameraPoints = [
      ...points,
      for (final visit in widget.route.visits)
        if (isValidCoordinate(visit.latitude, visit.longitude))
          LatLng(visit.latitude, visit.longitude),
    ];
    final bounds = LatLngBounds.fromPoints(cameraPoints);
    final routeDotMarkers = _routePointMarkers(points);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        key: const ValueKey('day-route-map'),
        height: 220,
        width: double.infinity,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(18),
              maxZoom: 18,
            ),
            cameraConstraint: const CameraConstraint.containLatitude(
              _webMercatorMaxLatitude,
              -_webMercatorMaxLatitude,
            ),
            minZoom: 3,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
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
            if (routeDotMarkers.isNotEmpty)
              MarkerClusterLayerWidget(
                key: const ValueKey('day-route-cluster-layer'),
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 34,
                  size: const Size(22, 22),
                  maxZoom: _maximumRouteZoom,
                  disableClusteringAtZoom: _disableRouteClusteringAtZoom,
                  padding: const EdgeInsets.all(18),
                  zoomToBoundsOnClick: true,
                  spiderfyCluster: false,
                  showPolygon: false,
                  centerMarkerOnClick: false,
                  markers: routeDotMarkers,
                  builder: (context, markers) =>
                      _MapRouteCluster(count: markers.length),
                  onMarkerTap: (marker) => _focusPoint(marker.point),
                ),
              ),
            MarkerLayer(markers: _markers(points, widget.route.visits)),
          ],
        ),
      ),
    );
  }

  List<Marker> _markers(List<LatLng> points, List<DayRouteVisit> visits) {
    final markers = <Marker>[
      Marker(
        point: points.first,
        width: 34,
        height: 34,
        child: GestureDetector(
          key: const ValueKey('day-route-start-marker'),
          onTap: () => _focusPoint(points.first),
          child: const _MapEndpointMarker(
            icon: Icons.play_arrow_rounded,
            background: AppColors.surface,
            foreground: AppColors.blueGrey,
          ),
        ),
      ),
    ];
    if (points.length > 1) {
      markers.add(
        Marker(
          point: points.last,
          width: 34,
          height: 34,
          child: GestureDetector(
            key: const ValueKey('day-route-end-marker'),
            onTap: () => _focusPoint(points.last),
            child: const _MapEndpointMarker(
              icon: Icons.stop_rounded,
              background: AppColors.ink,
              foreground: AppColors.surface,
            ),
          ),
        ),
      );
    }

    for (final visit in visits) {
      markers.add(
        Marker(
          point: LatLng(visit.latitude, visit.longitude),
          width: 32,
          height: 32,
          child: GestureDetector(
            key: const ValueKey('day-route-visit-marker'),
            onTap: () => _focusPoint(LatLng(visit.latitude, visit.longitude)),
            child: const _MapVisitMarker(),
          ),
        ),
      );
    }

    return markers;
  }

  List<Marker> _routePointMarkers(List<LatLng> points) {
    if (points.length <= 2) return const [];
    return [
      for (var index = 1; index < points.length - 1; index++)
        Marker(
          point: points[index],
          width: 10,
          height: 10,
          child: const _MapRoutePointDot(),
        ),
    ];
  }
}

int _routeMarkerCount(DayRouteSnapshot route) {
  if (route.points.isEmpty) return route.visits.length;
  return (route.points.length == 1 ? 1 : 2) + route.visits.length;
}

const _webMercatorMaxLatitude = 85.05112878;
const _minimumRouteZoom = 3.0;
const _focusedRouteZoom = 17.0;
const _maximumRouteZoom = 19.0;
const _disableRouteClusteringAtZoom = 18;

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

class _MapRoutePointDot extends StatelessWidget {
  const _MapRoutePointDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('day-route-point-dot'),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.74),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.surface.withValues(alpha: 0.88),
          width: 1.5,
        ),
      ),
    );
  }
}

class _MapRouteCluster extends StatelessWidget {
  const _MapRouteCluster({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('day-route-point-cluster'),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.82),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.surface.withValues(alpha: 0.9),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3317232E),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: AppColors.surface,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({required this.items, required this.onSavePlace});

  final List<DayTimelineItem> items;
  final ValueChanged<DayTimelineItem> onSavePlace;

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
            for (final item in items)
              _TimelineDetailRow(item: item, onSavePlace: onSavePlace),
          ],
        ),
      ),
    );
  }
}

class _TimelineDetailRow extends StatelessWidget {
  const _TimelineDetailRow({required this.item, required this.onSavePlace});

  final DayTimelineItem item;
  final ValueChanged<DayTimelineItem> onSavePlace;

  @override
  Widget build(BuildContext context) {
    final row = Row(
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
        if (item.canSaveAsPlace) ...[
          const SizedBox(width: 8),
          const Text(
            '저장',
            style: TextStyle(
              color: AppColors.blueGrey,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: item.canSaveAsPlace ? () => onSavePlace(item) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: row,
        ),
      ),
    );
  }
}

class _SavePlaceDialog extends StatefulWidget {
  const _SavePlaceDialog({required this.item});

  final DayTimelineItem item;

  @override
  State<_SavePlaceDialog> createState() => _SavePlaceDialogState();
}

class _SavePlaceDialogState extends State<_SavePlaceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '이 머문 곳을 저장할까요?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  key: const ValueKey('save-place-map'),
                  height: 180,
                  width: double.infinity,
                  child: PlaceMapPreview(
                    latitude: widget.item.latitude!,
                    longitude: widget.item.longitude!,
                    cacheKey:
                        'save-place-'
                        '${widget.item.latitude!.toStringAsFixed(5)}-'
                        '${widget.item.longitude!.toStringAsFixed(5)}',
                    mapKey: const ValueKey('save-place-preview-map'),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${widget.item.timeLabel} · 이 시간대에 머문 곳으로 보여요',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('save-place-name-field'),
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '장소 이름',
                  hintText: '예: 집, 학원, 카페',
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_controller.text),
                    child: const Text('저장'),
                  ),
                ],
              ),
            ],
          ),
        ),
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
