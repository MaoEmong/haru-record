import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/app_dependencies.dart';
import '../../app/app_providers.dart';
import '../../app/app_theme.dart';
import '../../core/geo/coordinate_validation.dart';
import '../maps/cached_map_snapshot.dart';
import '../places/place_cluster_repository.dart';
import '../places/place_label.dart';
import '../processing/location_post_processor.dart';
import '../storage/app_database.dart';
import '../timeline/day_activity_preview_repository.dart';
import '../timeline/day_route_models.dart';
import '../maps/map_tiles.dart';
import '../timeline/day_time_selection.dart';
import '../timeline/day_timeline_models.dart';
import 'home_view_model.dart';

part 'home_album_art.dart';
part 'home_player_widgets.dart';
part 'home_timeline_sections.dart';

typedef OpenTodayRecordsCallback =
    void Function(DayActivityPreview preview, Future<DayRouteSnapshot> route);
typedef OpenDayFlowCallback =
    void Function(DayActivityPreview preview, Future<DayRouteSnapshot> route);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    required this.refreshVersion,
    required this.entryVersion,
    this.onOpenTodayRecords,
    this.onOpenDayFlow,
    this.onOpenLatestInsight,
  });

  final int refreshVersion;
  final int entryVersion;
  final OpenTodayRecordsCallback? onOpenTodayRecords;
  final OpenDayFlowCallback? onOpenDayFlow;
  final ValueChanged<Insight>? onOpenLatestInsight;

  static Future<void> preloadInitialData(
    AppDependencies dependencies, {
    required int refreshVersion,
  }) {
    return _HomeScreenState.preloadInitialData(
      dependencies,
      refreshVersion: refreshVersion,
    );
  }

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _selectedRoutePointIndex;
  Timer? _cheerTimer;
  bool _cheerVisible = false;
  String _cheerMessage = _cheerMessages.first;

  static Future<void> preloadInitialData(
    AppDependencies dependencies, {
    required int refreshVersion,
  }) async {
    final settings = await dependencies.settingsRepository.load();
    await Future.wait([
      dependencies.trackingService.isTracking(),
      loadLatestInsight(dependencies),
      loadHomePlaces(dependencies),
      loadTodayPreview(dependencies, settings: settings),
      loadTodayRouteSnapshot(dependencies),
    ]);
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion) {
      setState(() {
        _selectedRoutePointIndex = null;
      });
    } else if (oldWidget.entryVersion != widget.entryVersion) {
      setState(() {
        _selectedRoutePointIndex = null;
      });
    }
  }

  @override
  void dispose() {
    _cheerTimer?.cancel();
    super.dispose();
  }

  void _toggleCheer() {
    if (_cheerVisible) {
      _hideCheer();
      return;
    }
    final index = math.Random().nextInt(_cheerMessages.length);
    _cheerTimer?.cancel();
    setState(() {
      _cheerMessage = _cheerMessages[index];
      _cheerVisible = true;
    });
    _cheerTimer = Timer(const Duration(seconds: 3), _hideCheer);
  }

  void _hideCheer() {
    _cheerTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _cheerVisible = false;
    });
  }

  bool _isPinningLocation = false;

  /// 최근에 기록된 위치를 방문한 곳(핑)으로 저장한다.
  /// 같은 반경 안에 이미 저장된 곳이 있으면 새로 만들지 않는다.
  Future<void> _pinCurrentLocation() async {
    if (_isPinningLocation) return;
    setState(() => _isPinningLocation = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dependencies = ref.read(appDependenciesProvider);
      // 네이티브 서비스가 쌓아둔 최신 이벤트를 먼저 반영해 "현재"에 가깝게.
      await dependencies.importPendingEvents();
      final latest =
          await (dependencies.database.select(dependencies.database.locationPoints)
                ..orderBy([(point) => OrderingTerm.desc(point.timestamp)])
                ..limit(1))
              .getSingleOrNull();
      if (latest == null ||
          DateTime.now().difference(latest.timestamp) >
              _pinFreshnessWindow) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('최근 위치 기록이 없어요. 위치 기록이 켜져 있는지 확인해주세요.'),
          ),
        );
        return;
      }

      final settings = await dependencies.settingsRepository.load();
      final match = await PlaceClusterRepository(dependencies.database)
          .findOrCreateForVisit(
            latitude: latest.latitude,
            longitude: latest.longitude,
            radiusMeters: settings.minimumMovementMeters.toDouble(),
            visitedAt: latest.timestamp,
          );
      if (!mounted) return;
      if (match.isNew) {
        ref.invalidate(homePlacesProvider(widget.refreshVersion));
        messenger.showSnackBar(
          const SnackBar(content: Text('현재 위치를 핑으로 추가했어요')),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('이미 추가된 곳이에요 (${placeLabel(match.cluster)})')),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('핑 추가에 실패했어요. 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _isPinningLocation = false);
    }
  }

  static const _pinFreshnessWindow = Duration(minutes: 15);

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(homeSettingsProvider(widget.refreshVersion));
    final tracking = ref.watch(homeTrackingProvider(widget.refreshVersion));
    final latestInsight = ref.watch(
      homeLatestInsightProvider(widget.refreshVersion),
    );
    final places = ref.watch(homePlacesProvider(widget.refreshVersion));
    final preview = ref.watch(todayPreviewProvider(widget.refreshVersion));
    final routeSnapshot = ref.watch(
      todayRouteSnapshotProvider(widget.refreshVersion),
    );
    final routeFuture = ref.watch(
      todayRouteSnapshotProvider(widget.refreshVersion).future,
    );

    final previewValue = preview.value ?? _emptyTodayPreview;
    final route = routeSnapshot.value;
    final knownPlaces = places.value ?? const <PlaceCluster>[];
    final isRecording =
        (tracking.value ?? false) || (settings.value?.trackingEnabled ?? false);
    final selection = _HomeTimeSelection.from(
      preview: previewValue,
      route: route,
      knownPlaces: knownPlaces,
      selectedIndex: _selectedRoutePointIndex,
    );

    return ListView(
      cacheExtent: 2400,
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        const _NowPlayingHeader(),
        _AlbumArtSection(
          isRecording: isRecording,
          route: route,
          selectedPointIndex: selection.selectedIndex,
        ),
        _TrackInfoRow(
          distanceKm: _distanceLabel(previewValue),
          placeCount: previewValue.visitCount ?? 0,
          cheerVisible: _cheerVisible,
          cheerMessage: _cheerMessage,
          onCheer: _toggleCheer,
          isLoading: preview.isLoading,
        ),
        _StatsChipRow(preview: previewValue, isLoading: preview.isLoading),
        const SizedBox(height: 10),
        _ProgressBar(
          progress: selection.progress,
          timeLabel: selection.timeLabel,
          onTap: widget.onOpenDayFlow == null || !preview.hasValue
              ? null
              : () => widget.onOpenDayFlow!(previewValue, routeFuture),
        ),
        _ControlsRow(
          preview: previewValue,
          route: routeFuture,
          onOpenTodayRecords: preview.hasValue
              ? widget.onOpenTodayRecords
              : null,
          onPinCurrentLocation: _isPinningLocation ? null : _pinCurrentLocation,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Divider(height: 1, color: AppColors.mpSurface),
        ),
        _CurrentLocationCard(item: selection.currentItem),
        _TodayVisitList(
          preview: previewValue,
          route: routeFuture,
          items: selection.visibleTimeline,
          onOpen: preview.hasValue ? widget.onOpenTodayRecords : null,
          isLoading: preview.isLoading,
        ),
        _DarkInsightCard(
          insight: latestInsight.value,
          onOpen: widget.onOpenLatestInsight,
        ),
        if (preview.hasError ||
            routeSnapshot.hasError ||
            settings.hasError ||
            tracking.hasError ||
            places.hasError ||
            latestInsight.hasError)
          _HomePartialError(
            onRetry: () {
              ref.invalidate(homeSettingsProvider(widget.refreshVersion));
              ref.invalidate(homeTrackingProvider(widget.refreshVersion));
              ref.invalidate(homeLatestInsightProvider(widget.refreshVersion));
              ref.invalidate(homePlacesProvider(widget.refreshVersion));
              ref.invalidate(todayPreviewProvider(widget.refreshVersion));
              ref.invalidate(todayRouteSnapshotProvider(widget.refreshVersion));
            },
          ),
      ],
    );
  }

  String _distanceLabel(DayActivityPreview preview) {
    final meters = preview.totalDistanceMeters;
    if (meters == null) return '--';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
}

class _HomePartialError extends StatelessWidget {
  const _HomePartialError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.mpSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.mpBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '일부 기록을 불러오지 못했어요',
                  style: TextStyle(
                    color: AppColors.mpTextSub,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('다시')),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTimeSelection {
  const _HomeTimeSelection({
    required this.selectedIndex,
    required this.progress,
    required this.timeLabel,
    required this.currentItem,
    required this.visibleTimeline,
    required this.isCurrent,
  });

  final int? selectedIndex;
  final double progress;
  final String timeLabel;
  final DayTimelineItem? currentItem;
  final List<DayTimelineItem> visibleTimeline;
  final bool isCurrent;

  factory _HomeTimeSelection.from({
    required DayActivityPreview preview,
    required DayRouteSnapshot? route,
    required List<PlaceCluster> knownPlaces,
    required int? selectedIndex,
  }) {
    final points = route?.points ?? const <DayRoutePoint>[];
    if (points.isEmpty) {
      final latest = preview.timeline.isEmpty ? null : preview.timeline.last;
      return _HomeTimeSelection(
        selectedIndex: null,
        progress: progressForTime(DateTime.now()),
        timeLabel: routeTimeLabel(DateTime.now()),
        currentItem: latest,
        visibleTimeline: preview.timeline,
        isCurrent: true,
      );
    }

    final isCurrentMode = selectedIndex == null;
    final effectiveIndex = isCurrentMode
        ? points.length - 1
        : selectedIndex.clamp(0, points.length - 1);
    final selectedPoint = points[effectiveIndex];
    final selectedTime = isCurrentMode
        ? DateTime.now()
        : selectedPoint.timestamp;
    final currentItemTime = isCurrentMode
        ? selectedPoint.timestamp
        : selectedTime;
    final visibleTimeline = timelineItemsAtOrBefore(
      preview.timeline,
      selectedTime,
    );
    final matchingItem = timelineItemAt(preview.timeline, currentItemTime);
    final knownPlace = _findKnownPlace(
      selectedPoint: selectedPoint,
      knownPlaces: knownPlaces,
    );

    return _HomeTimeSelection(
      selectedIndex: effectiveIndex,
      progress: progressForTime(selectedTime),
      timeLabel: routeTimeLabel(selectedTime),
      currentItem:
          matchingItem ??
          (knownPlace == null
              ? null
              : DayTimelineItem(
                  timeLabel: selectedPoint.timeLabel,
                  placeLabel: placeLabel(knownPlace),
                  durationLabel: '현재 위치',
                  startedAt: currentItemTime,
                  latitude: selectedPoint.latitude,
                  longitude: selectedPoint.longitude,
                  placeClusterId: knownPlace.id,
                )) ??
          DayTimelineItem(
            timeLabel: selectedPoint.timeLabel,
            placeLabel: '최근 기록 위치',
            durationLabel: '위치 기록',
            startedAt: currentItemTime,
            latitude: selectedPoint.latitude,
            longitude: selectedPoint.longitude,
          ),
      visibleTimeline: visibleTimeline,
      isCurrent: isCurrentMode,
    );
  }

  static PlaceCluster? _findKnownPlace({
    required DayRoutePoint selectedPoint,
    required List<PlaceCluster> knownPlaces,
  }) {
    return const LocationPostProcessor().findKnownPlace(
      latitude: selectedPoint.latitude,
      longitude: selectedPoint.longitude,
      knownPlaces: knownPlaces,
    );
  }
}

const _webMercatorMaxLatitude = 85.05112878;

const _emptyTodayPreview = DayActivityPreview(
  totalDistanceMeters: null,
  movingMinutes: null,
  visitCount: null,
  timeline: <DayTimelineItem>[],
  pointCount: 0,
  hasData: false,
);

const _cheerMessages = [
  '오늘 하루도 잘 부탁해요',
  '천천히 시작해도 괜찮아요',
  '잘하고 있어요',
  '오늘도 한 걸음씩',
  '이 정도면 충분해요',
  '오늘 하루 수고했어요',
  '오늘도 잘 버텼어요',
  '내일은 또 내일의 하루가 있어요',
];
