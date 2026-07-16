part of 'home_screen.dart';

class _NowPlayingHeader extends StatelessWidget {
  const _NowPlayingHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        children: [
          SizedBox(width: 32),
          Expanded(
            child: Text(
              'Now Playing',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.mpTextSub,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
          SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _AlbumArtSection extends StatelessWidget {
  const _AlbumArtSection({
    required this.isRecording,
    required this.route,
    required this.selectedPointIndex,
  });

  final bool isRecording;
  final DayRouteSnapshot? route;
  final int? selectedPointIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 20, 36, 16),
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.mpSurface),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (route == null)
                  const _MapLoadingArt()
                else
                  _RouteAlbumMap(
                    route: route!,
                    selectedPointIndex: selectedPointIndex,
                  ),
                const _AlbumMapShade(),
                if (isRecording)
                  const Positioned(
                    top: 14,
                    right: 14,
                    child: _RecordingBadge(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteAlbumMap extends StatelessWidget {
  const _RouteAlbumMap({required this.route, required this.selectedPointIndex});

  final DayRouteSnapshot route;
  final int? selectedPointIndex;

  @override
  Widget build(BuildContext context) {
    final pointEntries = route.points.indexed
        .where(
          (entry) => isValidCoordinate(entry.$2.latitude, entry.$2.longitude),
        )
        .map(
          (entry) =>
              MapEntry(entry.$1, LatLng(entry.$2.latitude, entry.$2.longitude)),
        )
        .toList(growable: false);
    final points = pointEntries
        .map((entry) => entry.value)
        .toList(growable: false);

    if (points.isEmpty) {
      return const _EmptyAlbumArt();
    }

    if (points.length == 1) {
      return _SinglePointAlbumMap(route: route, point: points.single);
    }

    final effectiveIndex = (selectedPointIndex ?? route.points.length - 1)
        .clamp(0, route.points.length - 1);
    final selectedEntry = pointEntries.lastWhere(
      (entry) => entry.key <= effectiveIndex,
      orElse: () => pointEntries.last,
    );
    final highlightedPoints = pointEntries
        .where((entry) => entry.key <= effectiveIndex)
        .map((entry) => entry.value)
        .toList(growable: false);

    final visitPoints = [
      for (final visit in route.visits)
        if (isValidCoordinate(visit.latitude, visit.longitude))
          LatLng(visit.latitude, visit.longitude),
    ];
    final cameraPoints = [...points, ...visitPoints];
    final markers = <Marker>[
      Marker(
        point: points.first,
        width: 24,
        height: 24,
        child: const _AlbumEndpointMarker(icon: Icons.play_arrow_rounded),
      ),
      Marker(
        point: points.last,
        width: 24,
        height: 24,
        child: const _AlbumEndpointMarker(icon: Icons.stop_rounded),
      ),
      for (final point in visitPoints)
        Marker(
          point: point,
          width: 28,
          height: 28,
          child: const _AlbumVisitMarker(),
        ),
      Marker(
        point: selectedEntry.value,
        width: 34,
        height: 34,
        child: const _AlbumSelectedPointMarker(),
      ),
    ];

    return _DeferredMapRender(
      placeholder: const _MapLoadingArt(),
      builder: (context) => FlutterMap(
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(cameraPoints),
            padding: const EdgeInsets.all(28),
            maxZoom: 18,
          ),
          cameraConstraint: const CameraConstraint.containLatitude(
            _webMercatorMaxLatitude,
            -_webMercatorMaxLatitude,
          ),
          minZoom: 3,
          maxZoom: 19,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: mapTileUrlTemplate,
            userAgentPackageName: 'com.maoemong.harurecord',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                color: AppColors.mpAccent.withValues(alpha: 0.28),
                strokeWidth: 3,
                borderColor: AppColors.mpBg.withValues(alpha: 0.55),
                borderStrokeWidth: 2,
              ),
              if (highlightedPoints.length > 1)
                Polyline(
                  points: highlightedPoints,
                  color: AppColors.mpAccent,
                  strokeWidth: 4,
                  borderColor: AppColors.mpBg.withValues(alpha: 0.9),
                  borderStrokeWidth: 2,
                ),
              if (highlightedPoints.length == 1)
                Polyline(
                  points: [highlightedPoints.single, selectedEntry.value],
                  color: AppColors.mpAccent,
                  strokeWidth: 4,
                  borderColor: AppColors.mpBg.withValues(alpha: 0.9),
                  borderStrokeWidth: 2,
                ),
            ],
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}

class _SinglePointAlbumMap extends StatelessWidget {
  const _SinglePointAlbumMap({required this.route, required this.point});

  final DayRouteSnapshot route;
  final LatLng point;

  @override
  Widget build(BuildContext context) {
    return CachedMapSnapshot(
      cacheKey: _singlePointSnapshotCacheKey(route, point),
      placeholder: const _MapLoadingArt(),
      initialChildDelay: const Duration(milliseconds: 420),
      captureDelay: const Duration(milliseconds: 1500),
      child: _DeferredMapRender(
        placeholder: const _MapLoadingArt(),
        builder: (context) => FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 16,
            cameraConstraint: const CameraConstraint.containLatitude(
              _webMercatorMaxLatitude,
              -_webMercatorMaxLatitude,
            ),
            minZoom: 3,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: mapTileUrlTemplate,
              userAgentPackageName: 'com.maoemong.harurecord',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 30,
                  height: 30,
                  child: const _AlbumVisitMarker(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumSelectedPointMarker extends StatelessWidget {
  const _AlbumSelectedPointMarker();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mpBg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.mpAccent, width: 3),
      ),
      child: const Center(
        child: SizedBox(
          width: 8,
          height: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.mpAccent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

String _singlePointSnapshotCacheKey(DayRouteSnapshot route, LatLng point) {
  return [
    'today-location',
    route.rawPointCount,
    route.points.length,
    route.visits.length,
    point.latitude.toStringAsFixed(5),
    point.longitude.toStringAsFixed(5),
  ].join('-');
}

class _DeferredMapRender extends StatefulWidget {
  const _DeferredMapRender({required this.builder, required this.placeholder});

  final WidgetBuilder builder;
  final Widget placeholder;

  @override
  State<_DeferredMapRender> createState() => _DeferredMapRenderState();
}

class _DeferredMapRenderState extends State<_DeferredMapRender> {
  Timer? _timer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() {
        _ready = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: _ready ? widget.builder(context) : widget.placeholder,
    );
  }
}

class _MapLoadingArt extends StatelessWidget {
  const _MapLoadingArt();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mpSurface2,
        border: Border.all(color: AppColors.mpBorder),
      ),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.mpAccent,
          ),
        ),
      ),
    );
  }
}

class _EmptyAlbumArt extends StatelessWidget {
  const _EmptyAlbumArt();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mpSurface2,
        border: Border.all(color: AppColors.mpBorder),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route_rounded, size: 54, color: AppColors.mpTextMuted),
            SizedBox(height: 14),
            Text(
              '아직 기록이 없어요',
              style: TextStyle(
                color: AppColors.mpText,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              '오늘 이동이 쌓이면 지도로 보여드릴게요',
              style: TextStyle(color: AppColors.mpTextSub, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumMapShade extends StatelessWidget {
  const _AlbumMapShade();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.mpBg.withValues(alpha: 0.06),
              AppColors.mpBg.withValues(alpha: 0.18),
              AppColors.mpBg.withValues(alpha: 0.36),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlbumEndpointMarker extends StatelessWidget {
  const _AlbumEndpointMarker({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mpBg,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.mpText, width: 1.5),
      ),
      child: Icon(icon, color: AppColors.mpAccent, size: 15),
    );
  }
}

class _AlbumVisitMarker extends StatelessWidget {
  const _AlbumVisitMarker();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mpAccent,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.mpText, width: 2),
      ),
      child: const Icon(Icons.place_rounded, color: AppColors.mpBg, size: 17),
    );
  }
}

class _RecordingBadge extends StatelessWidget {
  const _RecordingBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mpBg.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mpAccent.withValues(alpha: 0.45)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _GreenDot(size: 6),
            SizedBox(width: 6),
            Text(
              '기록 중',
              style: TextStyle(
                color: AppColors.mpAccent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
