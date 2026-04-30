import 'package:flutter/services.dart';

import '../../core/logging/app_logger.dart';
import '../settings/settings_models.dart';
import 'location_tracking_service.dart';
import 'tracking_channel_exception.dart';

class PlatformLocationTrackingService implements LocationTrackingService {
  PlatformLocationTrackingService({
    MethodChannel channel = const MethodChannel('daily_pattern/tracking'),
    Duration channelTimeout = defaultTrackingChannelTimeout,
  }) : _channel = channel,
       _channelTimeout = channelTimeout;

  final MethodChannel _channel;
  final Duration _channelTimeout;

  @override
  Future<void> startTracking(AppSettings settings) {
    return _invoke<void>('startTracking', {
      'minimumMovementMeters': settings.minimumMovementMeters,
      'minimumStayMinutes': settings.minimumStayMinutes,
      'rawLocationIntervalSeconds': 10,
    });
  }

  @override
  Future<void> stopTracking() {
    return _invoke<void>('stopTracking');
  }

  @override
  Future<bool> isTracking() async {
    try {
      return await _invoke<bool>('isTracking') ?? false;
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Tracking status channel call failed.',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel
          .invokeMethod<T>(method, arguments)
          .timeout(_channelTimeout);
    } catch (error) {
      throw trackingChannelException(method, error);
    }
  }
}
