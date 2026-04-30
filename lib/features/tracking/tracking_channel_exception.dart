import 'dart:async';

import 'package:flutter/services.dart';

const defaultTrackingChannelTimeout = Duration(seconds: 3);

class TrackingChannelException implements Exception {
  const TrackingChannelException({
    required this.operation,
    required this.message,
    this.code,
    this.cause,
  });

  factory TrackingChannelException.fromPlatformException(
    String operation,
    PlatformException error,
  ) {
    return TrackingChannelException(
      operation: operation,
      code: error.code,
      message: error.message ?? _defaultMessage(operation),
      cause: error,
    );
  }

  factory TrackingChannelException.missingPlugin(
    String operation,
    MissingPluginException error,
  ) {
    return TrackingChannelException(
      operation: operation,
      code: 'tracking_channel_missing',
      message: '기기 기록 기능을 사용할 수 없어요.',
      cause: error,
    );
  }

  factory TrackingChannelException.unexpected(String operation, Object error) {
    return TrackingChannelException(
      operation: operation,
      code: 'tracking_channel_unexpected',
      message: _defaultMessage(operation),
      cause: error,
    );
  }

  final String operation;
  final String? code;
  final String message;
  final Object? cause;

  @override
  String toString() {
    final prefix = code == null ? operation : '$operation/$code';
    return 'TrackingChannelException($prefix): $message';
  }
}

class TrackingChannelTimeoutException extends TrackingChannelException {
  TrackingChannelTimeoutException({
    required super.operation,
    required this.timeout,
    super.cause,
  }) : super(
         code: 'tracking_channel_timeout',
         message: '기기 기록 기능 응답이 지연되고 있어요.',
       );

  final Duration timeout;
}

TrackingChannelException trackingChannelException(
  String operation,
  Object error,
) {
  if (error is TrackingChannelException) return error;
  if (error is TimeoutException) {
    return TrackingChannelTimeoutException(
      operation: operation,
      timeout: error.duration ?? Duration.zero,
      cause: error,
    );
  }
  if (error is PlatformException) {
    return TrackingChannelException.fromPlatformException(operation, error);
  }
  if (error is MissingPluginException) {
    return TrackingChannelException.missingPlugin(operation, error);
  }
  return TrackingChannelException.unexpected(operation, error);
}

String _defaultMessage(String operation) {
  return switch (operation) {
    'startTracking' => '하루 기록을 시작하지 못했어요.',
    'stopTracking' => '하루 기록을 멈추지 못했어요.',
    'isTracking' => '기록 상태를 확인하지 못했어요.',
    'getEventFilePath' => '기기 기록 파일을 확인하지 못했어요.',
    _ => '기기 기록 기능을 처리하지 못했어요.',
  };
}
