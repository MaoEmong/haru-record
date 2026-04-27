import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../storage/app_database.dart';

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
          return const _PlaceExamples();
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
          children: [
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
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => onRename(place),
        child: DecoratedBox(
          decoration: AppThemeDecorations.inkCard(),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '가장 자주 머문 곳',
                  style: TextStyle(
                    color: AppColors.softBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  place.displayName ?? '이름을 정하지 않은 곳',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${place.visitCount}번 머문 곳',
                  style: const TextStyle(
                    color: Color(0xB3FCFDFE),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: (place.visitCount / 10).clamp(0.08, 1),
                          minHeight: 8,
                          backgroundColor: const Color(0x33FCFDFE),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.softBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.edit_outlined, color: AppColors.surface),
                  ],
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
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => onRename(place),
        child: DecoratedBox(
          decoration: AppThemeDecorations.softCard(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, color: AppColors.blueGrey),
                const Spacer(),
                Text(
                  place.displayName ?? '이름을 정하지 않은 곳',
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
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
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

class _PlaceExamples extends StatelessWidget {
  const _PlaceExamples();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: const [
        Text(
          '자주 머문 곳은 이렇게 보여요',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 10),
        _ExamplePlaceCard(title: '집 근처', subtitle: '3번 머문 곳'),
        SizedBox(height: 10),
        _ExamplePlaceCard(title: '자주 가는 카페', subtitle: '2번 머문 곳'),
      ],
    );
  }
}

class _ExamplePlaceCard extends StatelessWidget {
  const _ExamplePlaceCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppThemeDecorations.softCard(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: const Icon(Icons.place_outlined, color: AppColors.ink),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.muted),
        ),
        trailing: const Text(
          '예시',
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
