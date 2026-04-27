import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../storage/app_database.dart';

class PlaceManagementScreen extends StatefulWidget {
  const PlaceManagementScreen({super.key, required this.database});

  final AppDatabase database;

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
          title: const Text('Rename place'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Display name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
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
          padding: const EdgeInsets.all(16),
          itemCount: places.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final place = places[index];
            return ListTile(
              tileColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              leading: const Icon(Icons.place_outlined),
              title: Text(place.displayName ?? 'Unnamed place'),
              subtitle: Text('${place.visitCount} visits'),
              trailing: IconButton(
                tooltip: 'Rename',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _rename(place),
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
        child: Text('No places detected yet'),
      ),
    );
  }
}
