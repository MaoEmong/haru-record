import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_theme.dart';
import '../../shared/widgets/music_player_widgets.dart';
import '../storage/app_database.dart';
import 'place_label.dart';
import 'place_management_view_model.dart';
import 'place_map_preview.dart';

class PlaceManagementScreen extends ConsumerStatefulWidget {
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
  ConsumerState<PlaceManagementScreen> createState() =>
      _PlaceManagementScreenState();
}

class _PlaceManagementScreenState extends ConsumerState<PlaceManagementScreen> {
  PlacesQuery get _query => PlacesQuery(
    database: widget.database,
    refreshVersion: widget.refreshVersion,
  );

  Future<void> _rename(PlaceCluster place) async {
    final result = await showDialog<_PlaceEditResult>(
      context: context,
      builder: (context) => _RenamePlaceDialog(place: place),
    );
    if (result == null) return;

    await renamePlace(widget.database, place, result.name);
    if (result.pickedPhoto != null) {
      await setPlacePhoto(widget.database, place, result.pickedPhoto!);
    } else if (result.removePhoto) {
      await removePlacePhoto(widget.database, place);
    }
    ref.invalidate(placesSnapshotProvider(_query));
    widget.onPlacesChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final places = ref.watch(placesSnapshotProvider(_query));
    return places.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('방문한 곳을 불러오지 못했어요')),
      data: (data) {
        if (data.places.isEmpty) {
          return const _PlaceExamples();
        }
        return ListView(
          padding: EdgeInsets.only(
            bottom: 96 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            const MpPageHeader(
              title: '방문한 곳',
              subtitle: '자주 머문 장소를 라이브러리처럼 모아봐요.',
              trailing: _SortStatusPill(),
            ),
            const _PlaceGroupingNotice(),
            const SizedBox(height: 14),
            const MpSectionHeader(title: '자주 가는 곳'),
            _FeaturedPlaceCard(place: data.featuredPlace!, onRename: _rename),
            const SizedBox(height: 14),
            const MpSectionHeader(title: '전체 장소'),
            _PlaceList(
              places: data.namedPlaces,
              topVisitCount: data.topVisitCount,
              onRename: _rename,
            ),
            if (data.unnamedPlaces.isNotEmpty) ...[
              const SizedBox(height: 14),
              const MpSectionHeader(title: '이름 없는 곳'),
              _UnnamedPlaceGrid(places: data.unnamedPlaces, onRename: _rename),
            ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
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
                  const Positioned(
                    top: 14,
                    left: 14,
                    child: _FeaturedRankBadge(),
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
      ),
    );
  }
}

class _SortStatusPill extends StatelessWidget {
  const _SortStatusPill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mpSurface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.mpBorder),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Text(
          '방문 많은 순 ↓',
          style: TextStyle(
            color: AppColors.mpTextSub,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FeaturedRankBadge extends StatelessWidget {
  const _FeaturedRankBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mpAccent.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          '1위',
          style: TextStyle(
            color: AppColors.mpBg,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PlaceList extends StatelessWidget {
  const _PlaceList({
    required this.places,
    required this.topVisitCount,
    required this.onRename,
  });

  final List<PlaceCluster> places;
  final int topVisitCount;
  final ValueChanged<PlaceCluster> onRename;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          '이름을 정한 장소가 더 생기면 여기에 이어서 보여요.',
          style: TextStyle(color: AppColors.mpTextSub, fontSize: 13),
        ),
      );
    }
    return Column(
      children: [
        for (final place in places)
          _PlaceListItem(
            place: place,
            progress: (place.visitCount / topVisitCount).clamp(0.0, 1.0),
            onRename: onRename,
          ),
      ],
    );
  }
}

class _PlaceListItem extends StatelessWidget {
  const _PlaceListItem({
    required this.place,
    required this.progress,
    required this.onRename,
  });

  final PlaceCluster place;
  final double progress;
  final ValueChanged<PlaceCluster> onRename;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('place-card-${place.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onRename(place),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: [
              _PlaceMapThumbnail(place: place),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      placeLabel(place),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mpText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      placeAreaLabel(place),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.mpTextSub,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 54,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.mpAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${place.visitCount}회',
                      style: const TextStyle(
                        color: AppColors.mpTextSub,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _MicroProgressBar(value: progress),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnnamedPlaceGrid extends StatelessWidget {
  const _UnnamedPlaceGrid({required this.places, required this.onRename});

  final List<PlaceCluster> places;
  final ValueChanged<PlaceCluster> onRename;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
        return _UnnamedPlaceGridCard(place: places[index], onRename: onRename);
      },
    );
  }
}

class _UnnamedPlaceGridCard extends StatelessWidget {
  const _UnnamedPlaceGridCard({required this.place, required this.onRename});

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
                  child: _UnnamedPlaceGridCaption(place: place),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceMapThumbnail extends StatelessWidget {
  const _PlaceMapThumbnail({required this.place});

  final PlaceCluster place;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          children: [
            Positioned.fill(child: _PlaceMapPreview(place: place, zoom: 15.5)),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.mpBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicroProgressBar extends StatelessWidget {
  const _MicroProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        minHeight: 3,
        value: value,
        color: AppColors.mpAccent,
        backgroundColor: AppColors.mpBorder,
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
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 24,
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
          '${placeAreaLabel(place)} · ${place.visitCount}번 머문 곳',
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
      ],
    );
  }
}

class _UnnamedPlaceGridCaption extends StatelessWidget {
  const _UnnamedPlaceGridCaption({required this.place});

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
                placeAreaLabel(place),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${place.visitCount}번 머문 곳 · 이름 정하기',
                style: const TextStyle(
                  color: AppColors.mpAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
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
  const _PlaceMapPreview({required this.place, this.zoom = 16});

  final PlaceCluster place;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    // 사용자가 붙인 사진이 있으면 지도 대신 사진을 보여준다.
    final photoPath = place.photoPath;
    if (photoPath != null && File(photoPath).existsSync()) {
      return Image.file(
        File(photoPath),
        key: ValueKey('place-photo-${place.id}'),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _mapPreview(),
      );
    }
    return _mapPreview();
  }

  Widget _mapPreview() {
    return PlaceMapPreview(
      latitude: place.centerLatitude,
      longitude: place.centerLongitude,
      mapKey: ValueKey('place-map-${place.id}'),
      snapshotKey: ValueKey('map-snapshot-place-${place.id}'),
      cacheKey:
          'place-${place.id}-'
          '${place.centerLatitude.toStringAsFixed(5)}-'
          '${place.centerLongitude.toStringAsFixed(5)}-z${zoom.toStringAsFixed(1)}',
      zoom: zoom,
    );
  }
}

/// 장소 편집 다이얼로그의 결과. 이름과 사진 변경(선택/삭제)을 한 번에 담는다.
class _PlaceEditResult {
  const _PlaceEditResult({
    required this.name,
    this.pickedPhoto,
    this.removePhoto = false,
  });

  final String name;
  final File? pickedPhoto;
  final bool removePhoto;
}

class _RenamePlaceDialog extends StatefulWidget {
  const _RenamePlaceDialog({required this.place});

  final PlaceCluster place;

  @override
  State<_RenamePlaceDialog> createState() => _RenamePlaceDialogState();
}

class _RenamePlaceDialogState extends State<_RenamePlaceDialog> {
  late final TextEditingController _controller;
  File? _pickedPhoto;
  bool _photoRemoved = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.place.displayName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? get _previewPhotoPath {
    if (_pickedPhoto != null) return _pickedPhoto!.path;
    if (_photoRemoved) return null;
    final existing = widget.place.photoPath;
    if (existing != null && File(existing).existsSync()) return existing;
    return null;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _pickedPhoto = File(picked.path);
        _photoRemoved = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진을 가져오지 못했어요')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '장소 이름 바꾸기',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: _previewPhotoPath != null
                      ? Image.file(
                          File(_previewPhotoPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _PlaceMapPreview(place: widget.place, zoom: 16),
                        )
                      : _PlaceMapPreview(place: widget.place, zoom: 16),
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    key: const ValueKey('place-photo-camera'),
                    onPressed: () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('촬영'),
                  ),
                  TextButton.icon(
                    key: const ValueKey('place-photo-gallery'),
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('갤러리'),
                  ),
                  const Spacer(),
                  if (_previewPhotoPath != null)
                    TextButton.icon(
                      key: const ValueKey('place-photo-remove'),
                      onPressed: () => setState(() {
                        _pickedPhoto = null;
                        _photoRemoved = true;
                      }),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('사진 지우기'),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                placeAreaLabel(widget.place),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: '내가 부를 이름'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      _PlaceEditResult(
                        name: _controller.text,
                        pickedPhoto: _pickedPhoto,
                        removePhoto: _photoRemoved && _pickedPhoto == null,
                      ),
                    ),
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
  const _PlaceExamples();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(
        bottom: 96 + MediaQuery.paddingOf(context).bottom,
      ),
      children: const [
        MpPageHeader(title: '방문한 곳', subtitle: '아직 저장한 방문 장소가 없어요.'),
        SizedBox(height: 18),
        _EmptyPlacesMessage(),
        SizedBox(height: 18),
        MpSectionHeader(title: '이렇게 모여요'),
        _EmptyPlacePreviewRow(
          title: '자주 머문 곳',
          meta: '오늘 기록에서 머문 곳을 저장하면 여기에 쌓여요',
          value: '--회',
        ),
        _EmptyPlacePreviewRow(
          title: '이름 없는 곳',
          meta: '저장한 뒤 이름을 붙이면 내 장소가 돼요',
          value: '대기',
        ),
      ],
    );
  }
}

class _EmptyPlacesMessage extends StatelessWidget {
  const _EmptyPlacesMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.mpSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.mpBorder),
        ),
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '아직 라이브러리가 비어 있어요',
                style: TextStyle(
                  color: AppColors.mpText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '오늘 기록에서 머문 곳을 저장하면 자주 간 장소와 이름 없는 곳이 이곳에 모여요.',
                style: TextStyle(
                  color: AppColors.mpTextSub,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPlacePreviewRow extends StatelessWidget {
  const _EmptyPlacePreviewRow({
    required this.title,
    required this.meta,
    required this.value,
  });

  final String title;
  final String meta;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.42,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
            const _EmptyPlaceAvatar(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.mpText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.mpTextSub,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.mpTextSub,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlaceAvatar extends StatelessWidget {
  const _EmptyPlaceAvatar();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mpSurface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.mpBorder),
      ),
      child: const SizedBox(
        width: 52,
        height: 52,
        child: Icon(Icons.place_outlined, color: AppColors.mpTextSub, size: 24),
      ),
    );
  }
}
