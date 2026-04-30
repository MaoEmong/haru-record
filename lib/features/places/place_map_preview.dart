import 'dart:async';

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
        child: _DeferredPlaceMap(
          placeholder: const _PlaceMapPlaceholder(),
          builder: (context) => FlutterMap(
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
      ),
    );
  }
}

class _DeferredPlaceMap extends StatefulWidget {
  const _DeferredPlaceMap({required this.builder, required this.placeholder});

  final WidgetBuilder builder;
  final Widget placeholder;

  @override
  State<_DeferredPlaceMap> createState() => _DeferredPlaceMapState();
}

class _DeferredPlaceMapState extends State<_DeferredPlaceMap> {
  Timer? _timer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 260), () {
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
    return _ready ? widget.builder(context) : widget.placeholder;
  }
}

class _PlaceMapPlaceholder extends StatelessWidget {
  const _PlaceMapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceAlt,
      child: Center(
        child: Icon(
          Icons.map_rounded,
          color: AppColors.ink.withValues(alpha: 0.32),
          size: 34,
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
