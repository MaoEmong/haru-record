import 'package:flutter/services.dart';

import '../settings/settings_models.dart';
import 'location_tracking_service.dart';

class PlatformLocationTrackingService implements LocationTrackingService {
  PlatformLocationTrackingService({
    MethodChannel channel = const MethodChannel('daily_pattern/tracking'),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<void> startTracking(AppSettings settings) {
    return _channel.invokeMethod<void>('startTracking', {
      'minimumMovementMeters': settings.minimumMovementMeters,
      'minimumStayMinutes': settings.minimumStayMinutes,
    });
  }

  @override
  Future<void> stopTracking() {
    return _channel.invokeMethod<void>('stopTracking');
  }

  @override
  Future<bool> isTracking() async {
    return await _channel.invokeMethod<bool>('isTracking') ?? false;
  }
}
