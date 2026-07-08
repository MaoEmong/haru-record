import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/app_theme.dart';
import '../../core/geo/coordinate_validation.dart';
import '../settings/settings_repository.dart';
import '../storage/app_database.dart';
import 'day_activity_preview_repository.dart';
import 'day_detail_view_model.dart';
import 'day_route_models.dart';
import 'day_time_selection.dart';
import 'day_timeline_models.dart';

const _flowPlaybackStepDuration = Duration(milliseconds: 233);
const _flowPlaybackMoveDuration = Duration(milliseconds: 180);
const _webMercatorMaxLatitude = 85.05112878;
const _minimumFlowBoundsSpan = 0.0008;

class DayFlowPlaybackScreen extends ConsumerStatefulWidget {
  const DayFlowPlaybackScreen({
    super.key,
    required this.database,
    required this.date,
    this.settingsRepository,
    this.initialPreview,
    this.initialRoute,
  });

  final AppDatabase database;
  final DateTime date;
  final SettingsRepository? settingsRepository;
  final DayActivityPreview? initialPreview;
  final Future<DayRouteSnapshot>? initialRoute;

  @override
  ConsumerState<DayFlowPlaybackScreen> createState() =>
      _DayFlowPlaybackScreenState();
}

class _DayFlowPlaybackScreenState extends ConsumerState<DayFlowPlaybackScreen> {
  var _refreshVersion = 0;
  int? _selectedPointIndex;
  Timer? _playbackTimer;
  bool _isPlaying = false;

  @override
  void dispose() {
    _stopPlayback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = DayDetailQuery(
      database: widget.database,
      settingsRepository: widget.settingsRepository,
      date: widget.date,
      refreshVersion: _refreshVersion,
      initialPreview: widget.initialPreview,
      initialRoute: widget.initialRoute,
    );
    final preview = ref.watch(dayDetailPreviewProvider(query));
    final route = ref.watch(dayDetailRouteProvider(query));
    final title = _isToday(widget.date) ? '오늘의 흐름' : '그날의 흐름';

    return Scaffold(
      backgroundColor: AppColors.mpBg,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.mpBg,
        foregroundColor: AppColors.mpText,
        surfaceTintColor: Colors.transparent,
      ),
      body: route.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.mpAccent),
        ),
        error: (error, stackTrace) => _FlowError(
          onRetry: () {
            setState(() {
              _refreshVersion++;
              _selectedPointIndex = null;
            });
          },
        ),
        data: (route) {
          final window = playbackWindowForDate(
            date: widget.date,
            points: route.points,
            now: DateTime.now(),
          );
          if (route.points.isEmpty || window == null) {
            return _EmptyFlow(title: title);
          }

          final selectedIndex = _effectiveSelectedIndex(route);
          final selectedPoint = route.points[selectedIndex];
          final selectedItem = preview.value == null
              ? null
              : timelineItemAt(
                  preview.value!.timeline,
                  selectedPoint.timestamp,
                );
          return Column(
            children: [
              Expanded(
                child: _FlowMap(
                  route: route,
                  selectedPointIndex: selectedIndex,
                ),
              ),
              _FlowPlaybackPanel(
                route: route,
                window: window,
                selectedPointIndex: selectedIndex,
                selectedItem: selectedItem,
                isPlaying: _isPlaying,
                onPrevious: () => _moveBy(route, -1),
                onNext: () => _moveBy(route, 1),
                onTogglePlayback: () => _togglePlayback(route),
                onSeek: (progress) => _seek(route, window, progress),
              ),
            ],
          );
        },
      ),
    );
  }

  int _effectiveSelectedIndex(DayRouteSnapshot route) {
    if (route.points.isEmpty) return 0;
    final index =
        _selectedPointIndex ??
        (nearestRoutePointIndexForTime(route.points, DateTime.now()) ??
            route.points.length - 1);
    return index.clamp(0, route.points.length - 1);
  }

  void _seek(
    DayRouteSnapshot route,
    RoutePlaybackWindow window,
    double progress,
  ) {
    _pausePlayback();
    final time = playbackTimeFromProgress(window, progress);
    final index = nearestRoutePointIndexForTime(route.points, time);
    if (index == null) return;
    setState(() {
      _selectedPointIndex = index;
    });
  }

  void _moveBy(DayRouteSnapshot route, int delta) {
    _pausePlayback();
    if (route.points.isEmpty) return;
    setState(() {
      _selectedPointIndex = (_effectiveSelectedIndex(route) + delta).clamp(
        0,
        route.points.length - 1,
      );
    });
  }

  void _togglePlayback(DayRouteSnapshot route) {
    if (_isPlaying) {
      _pausePlayback();
      return;
    }
    if (route.points.length < 2) return;
    setState(() {
      if (_effectiveSelectedIndex(route) >= route.points.length - 1) {
        _selectedPointIndex = 0;
      }
      _isPlaying = true;
    });
    _playbackTimer = Timer.periodic(_flowPlaybackStepDuration, (_) {
      if (!mounted) return;
      final current = _effectiveSelectedIndex(route);
      if (current >= route.points.length - 1) {
        _pausePlayback();
        return;
      }
      setState(() {
        _selectedPointIndex = current + 1;
      });
    });
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    if (!_isPlaying) return;
    setState(() {
      _isPlaying = false;
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _isPlaying = false;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _FlowMap extends StatefulWidget {
  const _FlowMap({required this.route, required this.selectedPointIndex});

  final DayRouteSnapshot route;
  final int selectedPointIndex;

  @override
  State<_FlowMap> createState() => _FlowMapState();
}

class _FlowMapState extends State<_FlowMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _positionController;
  DayRoutePoint? _fromPoint;
  DayRoutePoint? _toPoint;

  @override
  void initState() {
    super.initState();
    _positionController = AnimationController(
      vsync: this,
      duration: _flowPlaybackMoveDuration,
    )..value = 1;
    _toPoint = _selectedValidRoutePoint();
    _fromPoint = _toPoint;
  }

  @override
  void didUpdateWidget(covariant _FlowMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextPoint = _selectedValidRoutePoint();
    if (nextPoint == null) {
      _fromPoint = null;
      _toPoint = null;
      _positionController.value = 1;
      return;
    }
    final currentTarget = _toPoint;
    final targetChanged =
        currentTarget == null ||
        currentTarget.latitude != nextPoint.latitude ||
        currentTarget.longitude != nextPoint.longitude;
    if (!targetChanged) return;

    _fromPoint = _displayPoint() ?? currentTarget ?? nextPoint;
    _toPoint = nextPoint;
    _positionController.forward(from: 0);
  }

  @override
  void dispose() {
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.route.points
        .where((point) => isValidCoordinate(point.latitude, point.longitude))
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList(growable: false);
    if (points.isEmpty) return const _EmptyMap();

    final selectedIndex = widget.selectedPointIndex.clamp(0, points.length - 1);
    final highlightedPoints = points.take(selectedIndex).toList();
    final cameraPoints = [
      ...points,
      for (final visit in widget.route.visits)
        if (isValidCoordinate(visit.latitude, visit.longitude))
          LatLng(visit.latitude, visit.longitude),
    ];
    final bounds = _safeFlowMapBounds(cameraPoints);

    return AnimatedBuilder(
      animation: _positionController,
      builder: (context, _) {
        final animatedPoint = _displayPoint();
        final animatedLatLng = animatedPoint == null
            ? points[selectedIndex]
            : LatLng(animatedPoint.latitude, animatedPoint.longitude);
        final animatedHighlightedPoints = [
          ...highlightedPoints,
          animatedLatLng,
        ];

        return FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(40),
              maxZoom: 17,
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
                if (points.length >= 2)
                  Polyline(
                    points: points,
                    color: AppColors.mpTextSub.withValues(alpha: 0.32),
                    strokeWidth: 4,
                    borderColor: AppColors.mpBg.withValues(alpha: 0.7),
                    borderStrokeWidth: 2,
                  ),
                if (animatedHighlightedPoints.length >= 2)
                  Polyline(
                    points: animatedHighlightedPoints,
                    color: AppColors.mpAccent,
                    strokeWidth: 6,
                    borderColor: AppColors.mpBg.withValues(alpha: 0.78),
                    borderStrokeWidth: 2,
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (final visit in widget.route.visits)
                  if (isValidCoordinate(visit.latitude, visit.longitude))
                    Marker(
                      point: LatLng(visit.latitude, visit.longitude),
                      width: 34,
                      height: 34,
                      child: const _FlowVisitMarker(),
                    ),
                Marker(
                  point: animatedLatLng,
                  width: 48,
                  height: 48,
                  child: const _FlowSelectedMarker(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  DayRoutePoint? _displayPoint() {
    final from = _fromPoint;
    final to = _toPoint;
    if (from == null || to == null) return to;
    final progress = Curves.easeOutCubic.transform(_positionController.value);
    return interpolateRoutePoint(from, to, progress);
  }

  DayRoutePoint? _selectedValidRoutePoint() {
    final points = widget.route.points
        .where((point) => isValidCoordinate(point.latitude, point.longitude))
        .toList(growable: false);
    if (points.isEmpty) return null;
    return points[widget.selectedPointIndex.clamp(0, points.length - 1)];
  }
}

LatLngBounds _safeFlowMapBounds(List<LatLng> points) {
  final bounds = LatLngBounds.fromPoints(points);
  final latitudeSpan = bounds.north - bounds.south;
  final longitudeSpan = bounds.east - bounds.west;
  if (latitudeSpan >= _minimumFlowBoundsSpan &&
      longitudeSpan >= _minimumFlowBoundsSpan) {
    return bounds;
  }

  final centerLatitude = ((bounds.north + bounds.south) / 2)
      .clamp(-_webMercatorMaxLatitude, _webMercatorMaxLatitude)
      .toDouble();
  final centerLongitude =
      ((bounds.east + bounds.west) / 2).clamp(-180.0, 180.0).toDouble();
  final latitudeHalfSpan =
      (latitudeSpan < _minimumFlowBoundsSpan
              ? _minimumFlowBoundsSpan
              : latitudeSpan) /
          2;
  final longitudeHalfSpan =
      (longitudeSpan < _minimumFlowBoundsSpan
              ? _minimumFlowBoundsSpan
              : longitudeSpan) /
          2;

  return LatLngBounds.unsafe(
    north: (centerLatitude + latitudeHalfSpan)
        .clamp(-_webMercatorMaxLatitude, _webMercatorMaxLatitude)
        .toDouble(),
    south: (centerLatitude - latitudeHalfSpan)
        .clamp(-_webMercatorMaxLatitude, _webMercatorMaxLatitude)
        .toDouble(),
    east: (centerLongitude + longitudeHalfSpan).clamp(-180.0, 180.0).toDouble(),
    west: (centerLongitude - longitudeHalfSpan).clamp(-180.0, 180.0).toDouble(),
  );
}

class _FlowPlaybackPanel extends StatefulWidget {
  const _FlowPlaybackPanel({
    required this.route,
    required this.window,
    required this.selectedPointIndex,
    required this.selectedItem,
    required this.isPlaying,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePlayback,
    required this.onSeek,
  });

  final DayRouteSnapshot route;
  final RoutePlaybackWindow window;
  final int selectedPointIndex;
  final DayTimelineItem? selectedItem;
  final bool isPlaying;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTogglePlayback;
  final ValueChanged<double> onSeek;

  @override
  State<_FlowPlaybackPanel> createState() => _FlowPlaybackPanelState();
}

class _FlowPlaybackPanelState extends State<_FlowPlaybackPanel> {
  double? _dragProgress;

  @override
  Widget build(BuildContext context) {
    final point = widget.route.points[widget.selectedPointIndex];
    final progress =
        _dragProgress ??
        progressForPlaybackTime(widget.window, point.timestamp);
    final visibleTime = _dragProgress == null
        ? point.timestamp
        : playbackTimeFromProgress(widget.window, _dragProgress!);
    final placeLabel = widget.selectedItem?.placeLabel ?? '이동 중 기록';

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.mpSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${routeTimeLabel(visibleTime)} · $placeLabel',
                key: const ValueKey('flow-selected-label'),
                style: const TextStyle(
                  color: AppColors.mpText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.selectedPointIndex + 1} / ${widget.route.points.length} · 정확도 ${point.accuracyMeters.round()}m',
                style: const TextStyle(
                  color: AppColors.mpTextSub,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              _FlowScrubber(
                progress: progress,
                onSeekUpdate: (value) {
                  setState(() {
                    _dragProgress = value;
                  });
                  widget.onSeek(value);
                },
                onSeekEnd: () {
                  setState(() {
                    _dragProgress = null;
                  });
                },
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    routeTimeLabel(widget.window.start),
                    style: const TextStyle(
                      color: AppColors.mpTextSub,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    routeTimeLabel(widget.window.end),
                    style: const TextStyle(
                      color: AppColors.mpTextSub,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    key: const ValueKey('flow-previous-point'),
                    onPressed: widget.selectedPointIndex == 0
                        ? null
                        : widget.onPrevious,
                    icon: const Icon(Icons.skip_previous_rounded),
                    color: AppColors.mpText,
                    iconSize: 36,
                  ),
                  const SizedBox(width: 22),
                  IconButton.filled(
                    key: const ValueKey('flow-toggle-playback'),
                    onPressed: widget.route.points.length < 2
                        ? null
                        : widget.onTogglePlayback,
                    icon: Icon(
                      widget.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    color: AppColors.mpBg,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.mpAccent,
                    ),
                    iconSize: 42,
                  ),
                  const SizedBox(width: 22),
                  IconButton(
                    key: const ValueKey('flow-next-point'),
                    onPressed:
                        widget.selectedPointIndex >=
                            widget.route.points.length - 1
                        ? null
                        : widget.onNext,
                    icon: const Icon(Icons.skip_next_rounded),
                    color: AppColors.mpText,
                    iconSize: 36,
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

class _FlowScrubber extends StatelessWidget {
  const _FlowScrubber({
    required this.progress,
    required this.onSeekUpdate,
    required this.onSeekEnd,
  });

  final double progress;
  final ValueChanged<double> onSeekUpdate;
  final VoidCallback onSeekEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        void seek(Offset localPosition) {
          if (constraints.maxWidth <= 0) return;
          onSeekUpdate(
            (localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0),
          );
        }

        final knobLeft = constraints.maxWidth * progress;
        return GestureDetector(
          key: const ValueKey('flow-time-scrubber'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            seek(details.localPosition);
            onSeekEnd();
          },
          onHorizontalDragStart: (details) => seek(details.localPosition),
          onHorizontalDragUpdate: (details) => seek(details.localPosition),
          onHorizontalDragEnd: (_) => onSeekEnd(),
          onHorizontalDragCancel: onSeekEnd,
          child: SizedBox(
            height: 34,
            child: Center(
              child: SizedBox(
                height: 16,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.mpSurface2,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.mpAccent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Positioned(
                      left: (knobLeft - 8).clamp(0, constraints.maxWidth - 16),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.mpAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FlowSelectedMarker extends StatelessWidget {
  const _FlowSelectedMarker();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mpAccent,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.mpText, width: 4),
        boxShadow: const [BoxShadow(color: Color(0x6618D36F), blurRadius: 16)],
      ),
      child: const Icon(Icons.radio_button_checked, color: Colors.white),
    );
  }
}

class _FlowVisitMarker extends StatelessWidget {
  const _FlowVisitMarker();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mpSurface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.mpAccent, width: 3),
      ),
      child: const Icon(
        Icons.place_rounded,
        color: AppColors.mpAccent,
        size: 18,
      ),
    );
  }
}

class _EmptyMap extends StatelessWidget {
  const _EmptyMap();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '표시할 이동 기록이 아직 없어요',
        style: TextStyle(color: AppColors.mpTextSub),
      ),
    );
  }
}

class _EmptyFlow extends StatelessWidget {
  const _EmptyFlow({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          '$title을 보여줄 위치 기록이 아직 없어요',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.mpText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _FlowError extends StatelessWidget {
  const _FlowError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(onPressed: onRetry, child: const Text('다시 불러오기')),
    );
  }
}
