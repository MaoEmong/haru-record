import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

abstract interface class NotificationAdapter {
  Future<bool?> requestPermission();

  Future<void> cancel(int id);

  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  });
}

class NotificationService {
  NotificationService(this._adapter);

  static const dailyInsightNotificationId = 2001;
  final NotificationAdapter _adapter;

  Future<bool?> requestNotificationPermission() {
    return _adapter.requestPermission();
  }

  Future<void> cancelDailyInsight() {
    return _adapter.cancel(dailyInsightNotificationId);
  }

  Future<void> scheduleDailyInsight({
    required int hour,
    required int minute,
    String? title,
    String? body,
  }) {
    _validateTime(hour: hour, minute: minute);
    return _adapter.scheduleDaily(
      id: dailyInsightNotificationId,
      hour: hour,
      minute: minute,
      title: title ?? '어제 하루를 정리했어요',
      body: body ?? '어떤 흐름이었는지 가볍게 확인해 보세요.',
    );
  }

  void _validateTime({required int hour, required int minute}) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'Must be between 0 and 23.');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(minute, 'minute', 'Must be between 0 and 59.');
    }
  }
}

class FlutterLocalNotificationAdapter implements NotificationAdapter {
  FlutterLocalNotificationAdapter({
    required tz.Location location,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _location = location;

  static const _androidChannel = AndroidNotificationChannel(
    'daily_pattern_insights',
    '하루 돌아보기',
    description: '하루 돌아보기 알림',
    importance: Importance.defaultImportance,
  );

  final FlutterLocalNotificationsPlugin _plugin;
  final tz.Location _location;
  Future<void>? _initialization;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings: initializationSettings);

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(_androidChannel);

      _initialized = true;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  @override
  Future<bool?> requestPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return android?.requestNotificationsPermission();
  }

  @override
  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await initialize();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOf(hour: hour, minute: minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_pattern_insights',
          '하루 돌아보기',
          channelDescription: '하루 돌아보기 알림',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(_location);
    var scheduled = tz.TZDateTime(
      _location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = tz.TZDateTime(
        _location,
        now.year,
        now.month,
        now.day + 1,
        hour,
        minute,
      );
    }
    return scheduled;
  }
}
