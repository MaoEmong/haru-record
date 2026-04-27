import '../storage/app_database.dart';

String placeLabel(PlaceCluster? place, {String fallback = '방문한 곳'}) {
  if (place == null) return fallback;
  return _firstNonEmpty([
        place.displayName,
        place.roadAddressName,
        place.addressName,
        place.regionName,
      ]) ??
      fallback;
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}
