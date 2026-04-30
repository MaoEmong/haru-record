import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_dependencies.dart';
import '../background/daily_insight_worker.dart';
import '../diagnostics/diagnostics_repository.dart';
import '../diagnostics/diagnostics_snapshot.dart';
import 'settings_models.dart';

final settingsProvider = FutureProvider.family<AppSettings, AppDependencies>((
  ref,
  dependencies,
) {
  return loadSettings(dependencies);
});

final settingsDiagnosticsProvider =
    FutureProvider.family<DiagnosticsSnapshot, SettingsDiagnosticsQuery>((
      ref,
      query,
    ) {
      return DiagnosticsRepository(query.dependencies.database).load();
    });

class SettingsDiagnosticsQuery {
  const SettingsDiagnosticsQuery({
    required this.dependencies,
    required this.refreshVersion,
  });

  final AppDependencies dependencies;
  final int refreshVersion;

  @override
  bool operator ==(Object other) {
    return other is SettingsDiagnosticsQuery &&
        identical(dependencies, other.dependencies) &&
        refreshVersion == other.refreshVersion;
  }

  @override
  int get hashCode =>
      Object.hash(identityHashCode(dependencies), refreshVersion);
}

Future<AppSettings> loadSettings(AppDependencies dependencies) {
  return dependencies.settingsRepository.load();
}

Future<AppSettings> saveSettings(
  AppDependencies dependencies,
  AppSettings settings,
) async {
  await dependencies.settingsRepository.save(settings);
  if (settings.trackingEnabled) {
    await dependencies.trackingService.stopTracking();
    await dependencies.trackingService.startTracking(settings);
  }
  return settings;
}

Future<ToggleTrackingResult> toggleTracking(
  AppDependencies dependencies, {
  required AppSettings settings,
  required bool enabled,
}) async {
  if (enabled) {
    final granted = await dependencies.permissionService
        .ensureLocationTrackingPermission();
    if (!granted) {
      return ToggleTrackingResult.permissionDenied;
    }
  }

  await dependencies.saveTrackingEnabled(settings: settings, enabled: enabled);
  return ToggleTrackingResult.updated(
    settings.copyWith(trackingEnabled: enabled),
  );
}

Future<ToggleNotificationResult> toggleNotifications(
  AppDependencies dependencies, {
  required AppSettings settings,
  required bool enabled,
}) async {
  final updated = settings.copyWith(notificationEnabled: enabled);
  if (enabled) {
    final granted = await dependencies.permissionService
        .ensureNotificationPermission();
    if (!granted) {
      return ToggleNotificationResult.permissionDenied;
    }
    await saveSettings(dependencies, updated);
    await dependencies.notificationService.scheduleDailyInsight(
      hour: updated.notificationHour,
      minute: updated.notificationMinute,
    );
  } else {
    await saveSettings(dependencies, updated);
    await dependencies.notificationService.cancelDailyInsight();
  }
  return ToggleNotificationResult.updated(updated);
}

Future<DailyProcessingResult> runDailyProcessing(AppDependencies dependencies) {
  return dependencies.runDailyProcessingNow();
}

Future<void> deleteRawLocationPoints(AppDependencies dependencies) {
  return dependencies.maintenanceService.deleteRawLocationPoints();
}

Future<void> deleteAllLocalData(AppDependencies dependencies) {
  return dependencies.maintenanceService.deleteAllLocalData();
}

sealed class ToggleTrackingResult {
  const ToggleTrackingResult();

  const factory ToggleTrackingResult.updated(AppSettings settings) =
      ToggleTrackingUpdated;

  static const permissionDenied = ToggleTrackingPermissionDenied();
}

class ToggleTrackingUpdated extends ToggleTrackingResult {
  const ToggleTrackingUpdated(this.settings);

  final AppSettings settings;
}

class ToggleTrackingPermissionDenied extends ToggleTrackingResult {
  const ToggleTrackingPermissionDenied();
}

sealed class ToggleNotificationResult {
  const ToggleNotificationResult();

  const factory ToggleNotificationResult.updated(AppSettings settings) =
      ToggleNotificationUpdated;

  static const permissionDenied = ToggleNotificationPermissionDenied();
}

class ToggleNotificationUpdated extends ToggleNotificationResult {
  const ToggleNotificationUpdated(this.settings);

  final AppSettings settings;
}

class ToggleNotificationPermissionDenied extends ToggleNotificationResult {
  const ToggleNotificationPermissionDenied();
}
