import '../features/settings/settings_repository.dart';
import '../features/tracking/location_tracking_service.dart';

class TrackingReconciliationService {
  const TrackingReconciliationService({
    required SettingsRepository settingsRepository,
    required LocationTrackingService trackingService,
  }) : _settingsRepository = settingsRepository,
       _trackingService = trackingService;

  final SettingsRepository _settingsRepository;
  final LocationTrackingService _trackingService;

  Future<void> reconcile() async {
    final settings = await _settingsRepository.load();
    if (!settings.trackingEnabled) return;
    if (await _trackingService.isTracking()) return;
    await _trackingService.startTracking(settings);
  }
}
