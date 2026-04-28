import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/app_theme.dart';
import '../maps/cached_map_snapshot.dart';

class PlaceMapPreview extends StatelessWidget {
  const PlaceMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.cacheKey,
    this.mapKey,
    this.snapshotKey,
    this.zoom = 16,
  });

  final double latitude;
  final double longitude;
  final String cacheKey;
  final Key? mapKey;
  final Key? snapshotKey;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(latitude, longitude);
    return IgnorePointer(
      child: CachedMapSnapshot(
        key: snapshotKey ?? ValueKey('map-snapshot-$cacheKey'),
        cacheKey: cacheKey,
        child: FlutterMap(
          key: mapKey,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.projectapp_1',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 34,
                  height: 34,
                  child: const PlacePinBadge(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PlacePinBadge extends StatelessWidget {
  const PlacePinBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink,
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
      child: const Icon(
        Icons.place_rounded,
        color: AppColors.surface,
        size: 18,
      ),
    );
  }
}
