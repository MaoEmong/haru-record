import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/app_theme.dart';
import '../../app/responsive_type.dart';
import '../../core/geo/coordinate_validation.dart';
import '../../core/time/date_key.dart';
import '../places/place_cluster_repository.dart';
import '../places/place_map_preview.dart';
import '../settings/settings_repository.dart';
import '../storage/app_database.dart';
import 'day_activity_preview_repository.dart';
import 'day_detail_view_model.dart';
import 'day_flow_playback_screen.dart';
import 'day_route_models.dart';
import 'day_timeline_models.dart';

part 'day_detail_sections.dart';
part 'day_detail_state_widgets.dart';
part 'day_detail_header.dart';
part 'day_detail_summary.dart';
part 'day_detail_route_preview.dart';
part 'day_detail_route_map.dart';
part 'day_detail_timeline.dart';
part 'day_detail_save_place_dialog.dart';

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
              dateLabel: dateKey(widget.date),
              title: widget.title,
              body: widget.body,
            ),
            const SizedBox(height: 12),
            _SummarySection(preview: preview),
            const SizedBox(height: 12),
            _RoutePreviewSection(
              route: route,
              preview: preview,
              dateKey: dateKey(widget.date),
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
