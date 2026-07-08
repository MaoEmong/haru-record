import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/app_theme.dart';
import '../../app/responsive_type.dart';
import '../../core/geo/coordinate_validation.dart';
import '../places/place_cluster_repository.dart';
import '../places/place_map_preview.dart';
import '../settings/settings_repository.dart';
import '../storage/app_database.dart';
import 'day_activity_preview_repository.dart';
import 'day_detail_view_model.dart';
import 'day_flow_playback_screen.dart';
import 'day_route_models.dart';
import 'day_timeline_models.dart';

class DayDetailScreen extends ConsumerStatefulWidget {
  const DayDetailScreen({
    super.key,
    required this.database,
    required this.date,
    this.settingsRepository,
    this.title,
    this.body,
    this.initialPreview,
    this.initialRoute,
    this.appBarTitle = '하루 자세히 보기',
  });

  final AppDatabase database;
  final DateTime date;
  final SettingsRepository? settingsRepository;
  final String? title;
  final String? body;
  final DayActivityPreview? initialPreview;
  final Future<DayRouteSnapshot>? initialRoute;
  final String appBarTitle;

  @override
  ConsumerState<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends ConsumerState<DayDetailScreen> {
  var _refreshVersion = 0;

  DayDetailQuery get _query => DayDetailQuery(
    database: widget.database,
    settingsRepository: widget.settingsRepository,
    date: widget.date,
    refreshVersion: _refreshVersion,
    initialPreview: widget.initialPreview,
    initialRoute: widget.initialRoute,
  );

  @override
  Widget build(BuildContext context) {
    final query = _query;
    final preview = ref.watch(dayDetailPreviewProvider(query));
    final route = ref.watch(dayDetailRouteProvider(query));
    return Scaffold(
      appBar: AppBar(title: Text(widget.appBarTitle)),
      body: SafeArea(
        child: ListView(
          cacheExtent: 1200,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _ReflectionHeader(
              dateLabel: _dateKey(widget.date),
              title: widget.title,
              body: widget.body,
            ),
            const SizedBox(height: 12),
            _SummarySection(preview: preview),
            const SizedBox(height: 12),
            _RoutePreviewSection(
              route: route,
              preview: preview,
              dateKey: _dateKey(widget.date),
              date: widget.date,
              database: widget.database,
              settingsRepository: widget.settingsRepository,
              initialPreview: widget.initialPreview,
              initialRoute: widget.initialRoute,
            ),
            const SizedBox(height: 12),
            _RouteSummarySection(
              preview: preview,
              onSavePlace: _saveTimelinePlace,
            ),
          ],
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
      _refreshVersion++;
    });
    ref.invalidate(dayDetailPreviewProvider(_query));
    ref.invalidate(dayDetailRouteProvider(_query));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('방문한 곳에 저장했어요')));
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.preview});

  final AsyncValue<DayActivityPreview> preview;

  @override
  Widget build(BuildContext context) {
    return preview.when(
      loading: () => const _SummaryLoadingCard(),
      error: (_, _) => const _SectionErrorCard(),
      data: (preview) => _SummaryCard(preview: preview),
    );
  }
}

class _RoutePreviewSection extends StatelessWidget {
  const _RoutePreviewSection({
    required this.route,
    required this.preview,
    required this.dateKey,
    required this.date,
    required this.database,
    required this.settingsRepository,
    required this.initialPreview,
    required this.initialRoute,
  });

  final AsyncValue<DayRouteSnapshot> route;
  final AsyncValue<DayActivityPreview> preview;
  final String dateKey;
  final DateTime date;
  final AppDatabase database;
  final SettingsRepository? settingsRepository;
  final DayActivityPreview? initialPreview;
  final Future<DayRouteSnapshot>? initialRoute;

  @override
  Widget build(BuildContext context) {
    return route.when(
      loading: () => const _RouteLoadingCard(),
      error: (_, _) => const _SectionErrorCard(),
      data: (route) => _RoutePreviewCard(
        route: route,
        dateKey: dateKey,
        date: date,
        database: database,
        settingsRepository: settingsRepository,
        initialPreview: initialPreview ?? preview.value,
        initialRoute: initialRoute ?? Future.value(route),
      ),
    );
  }
}

class _RouteSummarySection extends StatelessWidget {
  const _RouteSummarySection({
    required this.preview,
    required this.onSavePlace,
  });

  final AsyncValue<DayActivityPreview> preview;
  final ValueChanged<DayTimelineItem> onSavePlace;

  @override
  Widget build(BuildContext context) {
    return preview.when(
      loading: () => const _RouteSummaryLoadingCard(),
      error: (_, _) => const _SectionErrorCard(),
      data: (preview) =>
          _RouteSummaryCard(items: preview.timeline, onSavePlace: onSavePlace),
    );
  }
}

class _SummaryLoadingCard extends StatelessWidget {
  const _SummaryLoadingCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _LoadingLine(width: 96, height: 18),
            SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [_LoadingPill(width: 78), _LoadingPill(width: 96)],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteLoadingCard extends StatelessWidget {
  const _RouteLoadingCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(color: AppColors.surfaceAlt),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _LoadingLine(width: 96, height: 18),
            SizedBox(height: 8),
            _LoadingLine(width: 120, height: 14),
            SizedBox(height: 12),
            _MapPlaceholderCard(),
            SizedBox(height: 12),
            _LoadingLine(width: 110, height: 14),
          ],
        ),
      ),
    );
  }
}

class _RouteSummaryLoadingCard extends StatelessWidget {
  const _RouteSummaryLoadingCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _LoadingLine(width: 96, height: 18),
            SizedBox(height: 12),
            _LoadingLine(width: 180, height: 16),
            SizedBox(height: 14),
            _LoadingLine(width: double.infinity, height: 14),
            SizedBox(height: 10),
            _LoadingLine(width: 220, height: 14),
          ],
        ),
      ),
    );
  }
}

class _MapPlaceholderCard extends StatelessWidget {
  const _MapPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: const SizedBox(
        height: 220,
        width: double.infinity,
        child: Center(
          child: Text(
            '이동 경로를 불러오는 중',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.softBlue.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _SectionErrorCard extends StatelessWidget {
  const _SectionErrorCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Text('데이터를 불러오지 못했어요', style: TextStyle(color: AppColors.muted)),
      ),
    );
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
  const _RoutePreviewCard({
    required this.route,
    required this.dateKey,
    required this.date,
    required this.database,
    required this.settingsRepository,
    required this.initialPreview,
    required this.initialRoute,
  });

  final DayRouteSnapshot route;
  final String dateKey;
  final DateTime date;
  final AppDatabase database;
  final SettingsRepository? settingsRepository;
  final DayActivityPreview? initialPreview;
  final Future<DayRouteSnapshot> initialRoute;

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
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const ValueKey('day-detail-open-flow'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => DayFlowPlaybackScreen(
                          database: database,
                          date: date,
                          settingsRepository: settingsRepository,
                          initialPreview: initialPreview,
                          initialRoute: initialRoute,
                        ),
                      ),
                    );
                  },
                  child: const Text('그날의 흐름 보기'),
                ),
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
              userAgentPackageName: 'com.maoemong.harurecord',
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
