import '../settings/settings_models.dart';

abstract interface class LocationTrackingService {
  Future<void> startTracking(AppSettings settings);
  Future<void> stopTracking();
  Future<bool> isTracking();
}
