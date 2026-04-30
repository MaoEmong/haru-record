import '../features/background/daily_insight_worker.dart';
import '../features/notifications/notification_service.dart';
import '../features/settings/settings_repository.dart';
import '../features/storage/app_database.dart';
import '../features/tracking/location_event_importer.dart';

class DailyProcessingService {
  const DailyProcessingService({
    required AppDatabase database,
    required SettingsRepository settingsRepository,
    required NotificationService notificationService,
    required Future<LocationEventImportResult> Function() importPendingEvents,
    Future<DailyProcessingResult> Function()? runDailyProcessingOverride,
  }) : _database = database,
       _settingsRepository = settingsRepository,
       _notificationService = notificationService,
       _importPendingEvents = importPendingEvents,
       _runDailyProcessingOverride = runDailyProcessingOverride;

  final AppDatabase _database;
  final SettingsRepository _settingsRepository;
  final NotificationService _notificationService;
  final Future<LocationEventImportResult> Function() _importPendingEvents;
  final Future<DailyProcessingResult> Function()? _runDailyProcessingOverride;

  Future<DailyProcessingResult> run({DateTime? now}) async {
    if (_runDailyProcessingOverride != null) {
      return await _runDailyProcessingOverride();
    }
    final settings = await _settingsRepository.load();
    final processor = DailyInsightProcessor(
      database: _database,
      notificationService: _notificationService,
      importPendingEvents: _importPendingEvents,
      settings: settings,
    );
    return await processor.run(now: now ?? DateTime.now());
  }
}
