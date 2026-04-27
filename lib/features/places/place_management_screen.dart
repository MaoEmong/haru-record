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
    final controller = TextEditingController(text: place.displayName ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('이곳의 이름 바꾸기'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: '내가 부를 이름'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
    controller.dispose();
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
          return const _EmptyPlaces();
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: places.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final place = places[index];
            return DecoratedBox(
              decoration: AppThemeDecorations.softCard(),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                leading: const Icon(Icons.place_outlined, color: AppColors.ink),
                title: Text(
                  place.displayName ?? '이름을 정하지 않은 곳',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${place.visitCount}번 머문 곳',
                  style: const TextStyle(color: AppColors.muted),
                ),
                trailing: IconButton(
                  tooltip: '이름 바꾸기',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _rename(place),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyPlaces extends StatelessWidget {
  const _EmptyPlaces();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('아직 자주 머문 곳이 없어요'),
      ),
    );
  }
}
