import '../features/settings/settings_models.dart';
import '../features/settings/settings_repository.dart';
import '../features/tracking/location_tracking_service.dart';

class TrackingSettingsService {
  const TrackingSettingsService({
    required SettingsRepository settingsRepository,
    required LocationTrackingService trackingService,
  }) : _settingsRepository = settingsRepository,
       _trackingService = trackingService;

  final SettingsRepository _settingsRepository;
  final LocationTrackingService _trackingService;

  Future<void> saveTrackingEnabled({
    required AppSettings settings,
    required bool enabled,
  }) async {
    final updated = settings.copyWith(trackingEnabled: enabled);
    if (enabled) {
      await _trackingService.startTracking(updated);
    } else {
      await _trackingService.stopTracking();
    }
    await _settingsRepository.save(updated);
  }
}
