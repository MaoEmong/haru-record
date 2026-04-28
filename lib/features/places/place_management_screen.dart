import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../app/responsive_type.dart';
import '../storage/app_database.dart';
import 'place_label.dart';
import 'place_map_preview.dart';

class PlaceManagementScreen extends StatefulWidget {
  const PlaceManagementScreen({
    super.key,
    required this.database,
    required this.refreshVersion,
    this.onPlacesChanged,
  });

  final AppDatabase database;
  final int refreshVersion;
  final VoidCallback? onPlacesChanged;

  @override
  State<PlaceManagementScreen> createState() => _PlaceManagementScreenState();
}

class _PlaceManagementScreenState extends State<PlaceManagementScreen> {
  late Future<List<PlaceCluster>> _places;

  @override
  void initState() {
    super.initState();
    _places = _load();
  }

  @override
  void didUpdateWidget(covariant PlaceManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion) {
      setState(() {
        _places = _load();
      });
    }
  }

  Future<List<PlaceCluster>> _load() async {
    final places = await widget.database
        .select(widget.database.placeClusters)
        .get();
    return places..sort((a, b) => b.visitCount.compareTo(a.visitCount));
  }

  Future<void> _rename(PlaceCluster place) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _RenamePlaceDialog(initialName: place.displayName),
    );
    if (name == null) return;

    final normalized = name.trim();
    await (widget.database.update(
      widget.database.placeClusters,
    )..where((row) => row.id.equals(place.id))).write(
      PlaceClustersCompanion(
        displayName: Value(normalized.isEmpty ? null : normalized),
        updatedAt: Value(DateTime.now()),
      ),
    );
    setState(() {
      _places = _load();
    });
    widget.onPlacesChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PlaceCluster>>(
      future: _places,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final places = snapshot.data!;
        if (places.isEmpty) {
          return _PlaceExamples();
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
            const _PlaceGroupingNotice(),
            const SizedBox(height: 14),
            _FeaturedPlaceCard(place: places.first, onRename: _rename),
            const SizedBox(height: 14),
            _PlaceGrid(places: places.skip(1).toList(), onRename: _rename),
          ],
        );
      },
    );
  }
}

class _FeaturedPlaceCard extends StatelessWidget {
  const _FeaturedPlaceCard({required this.place, required this.onRename});

  final PlaceCluster place;
  final ValueChanged<PlaceCluster> onRename;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('place-card-${place.id}'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => onRename(place),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                Positioned.fill(child: _PlaceMapPreview(place: place)),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                _PlaceCaptionGradient(
                  borderRadius: 28,
                  child: _FeaturedPlaceCaption(place: place),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceGrid extends StatelessWidget {
  const _PlaceGrid({required this.places, required this.onRename});

  final List<PlaceCluster> places;
  final ValueChanged<PlaceCluster> onRename;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return Text(
        '조금 더 기록이 쌓이면 다른 장소도 이어서 보여요.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: places.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.06,
      ),
      itemBuilder: (context, index) {
        return _PlaceGridCard(place: places[index], onRename: onRename);
      },
    );
  }
}

class _PlaceGridCard extends StatelessWidget {
  const _PlaceGridCard({required this.place, required this.onRename});

  final PlaceCluster place;
  final ValueChanged<PlaceCluster> onRename;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('place-card-${place.id}'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => onRename(place),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: DecoratedBox(
            decoration: AppThemeDecorations.softCard(),
            child: Stack(
              children: [
                Positioned.fill(child: _PlaceMapPreview(place: place)),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                const Positioned(top: 16, left: 16, child: PlacePinBadge()),
                _PlaceCaptionGradient(
                  borderRadius: 24,
                  compact: true,
                  child: _PlaceGridCaption(place: place),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceCaptionGradient extends StatelessWidget {
  const _PlaceCaptionGradient({
    required this.child,
    required this.borderRadius,
    this.compact = false,
  });

  final Widget child;
  final double borderRadius;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(borderRadius),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surface.withValues(alpha: 0),
              AppColors.surface.withValues(alpha: 0.78),
              AppColors.surface.withValues(alpha: 0.94),
            ],
          ),
        ),
        child: Padding(
          padding: compact
              ? const EdgeInsets.fromLTRB(14, 40, 14, 14)
              : const EdgeInsets.fromLTRB(22, 62, 22, 22),
          child: child,
        ),
      ),
    );
  }
}

class _FeaturedPlaceCaption extends StatelessWidget {
  const _FeaturedPlaceCaption({required this.place});

  final PlaceCluster place;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '가장 많이 머문 곳',
          style: TextStyle(
            color: AppColors.blueGrey,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                placeLabel(place),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: responsiveTitleFontSize(context, 24),
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const _EditPill(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${place.visitCount}번 머문 곳',
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
      ],
    );
  }
}

class _PlaceGridCaption extends StatelessWidget {
  const _PlaceGridCaption({required this.place});

  final PlaceCluster place;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                placeLabel(place),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${place.visitCount}번 머문 곳',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const _EditPill(compact: true),
      ],
    );
  }
}

class _EditPill extends StatelessWidget {
  const _EditPill({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 6 : 8),
        child: Icon(
          Icons.edit_outlined,
          color: AppColors.ink,
          size: compact ? 15 : 17,
        ),
      ),
    );
  }
}

class _PlaceMapPreview extends StatelessWidget {
  const _PlaceMapPreview({required this.place});

  final PlaceCluster place;

  @override
  Widget build(BuildContext context) {
    return PlaceMapPreview(
      latitude: place.centerLatitude,
      longitude: place.centerLongitude,
      mapKey: ValueKey('place-map-${place.id}'),
      snapshotKey: ValueKey('map-snapshot-place-${place.id}'),
      cacheKey:
          'place-${place.id}-'
          '${place.centerLatitude.toStringAsFixed(5)}-'
          '${place.centerLongitude.toStringAsFixed(5)}-z16',
    );
  }
}

class _RenamePlaceDialog extends StatefulWidget {
  const _RenamePlaceDialog({required this.initialName});

  final String? initialName;

  @override
  State<_RenamePlaceDialog> createState() => _RenamePlaceDialogState();
}

class _RenamePlaceDialogState extends State<_RenamePlaceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('이곳의 이름 바꾸기'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: '내가 부를 이름'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('저장'),
        ),
      ],
    );
  }
}

class _PlaceGroupingNotice extends StatelessWidget {
  const _PlaceGroupingNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.blueGrey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '머문 위치가 생기면 이곳에 방문한 곳으로 모아요. 가까운 위치는 같은 장소로 묶고, 이름은 눌러서 바꿀 수 있어요.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceExamples extends StatelessWidget {
  _PlaceExamples();

  final List<PlaceCluster> _places = _examplePlaces();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        const _PlaceGroupingNotice(),
        const SizedBox(height: 14),
        Text(
          '방문한 곳은 이렇게 보여요',
          style: TextStyle(
            fontSize: responsiveTitleFontSize(context, 20),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '실제 기록이 쌓이면 아래처럼 지도 위에 장소가 표시돼요.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        _FeaturedPlaceCard(place: _places.first, onRename: (_) {}),
        const SizedBox(height: 14),
        _PlaceGrid(places: _places.skip(1).toList(), onRename: (_) {}),
      ],
    );
  }
}

List<PlaceCluster> _examplePlaces() {
  final now = DateTime(2026, 4, 27);
  return [
    PlaceCluster(
      id: -101,
      centerLatitude: 37.5665,
      centerLongitude: 126.978,
      radiusMeters: 80,
      roadAddressName: '서울 중구 세종대로 근처',
      createdAt: now,
      updatedAt: now,
      visitCount: 4,
    ),
    PlaceCluster(
      id: -102,
      centerLatitude: 37.5559,
      centerLongitude: 126.9723,
      radiusMeters: 70,
      displayName: '카페로 이름 바꾼 곳',
      addressName: '서울 용산구 근처',
      createdAt: now,
      updatedAt: now,
      visitCount: 2,
    ),
    PlaceCluster(
      id: -103,
      centerLatitude: 37.5512,
      centerLongitude: 126.9882,
      radiusMeters: 70,
      addressName: '서울 중구 근처',
      createdAt: now,
      updatedAt: now,
      visitCount: 1,
    ),
  ];
}
