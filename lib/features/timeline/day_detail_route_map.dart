part of 'day_detail_screen.dart';

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
