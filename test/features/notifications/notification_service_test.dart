import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/notifications/notification_service.dart';

void main() {
  test('schedules daily insight notification at configured time', () async {
    final adapter = FakeNotificationAdapter();
    final service = NotificationService(adapter);

    await service.scheduleDailyInsight(hour: 9, minute: 0);

    expect(adapter.scheduledHour, 9);
    expect(adapter.scheduledMinute, 0);
    expect(adapter.title, 'Your daily insight is ready');
  });

  test('requests notification permission separately from scheduling', () async {
    final adapter = FakeNotificationAdapter();
    final service = NotificationService(adapter);

    final granted = await service.requestNotificationPermission();

    expect(granted, isTrue);
    expect(adapter.permissionRequestCount, 1);
    expect(adapter.scheduledHour, isNull);
  });

  test('rejects invalid notification times', () async {
    final adapter = FakeNotificationAdapter();
    final service = NotificationService(adapter);

    expect(
      () => service.scheduleDailyInsight(hour: 24, minute: 0),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => service.scheduleDailyInsight(hour: 9, minute: -1),
      throwsA(isA<ArgumentError>()),
    );
    expect(adapter.scheduledHour, isNull);
  });
}

class FakeNotificationAdapter implements NotificationAdapter {
  int? scheduledHour;
  int? scheduledMinute;
  String? title;
  int permissionRequestCount = 0;

  @override
  Future<bool?> requestPermission() async {
    permissionRequestCount++;
    return true;
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    scheduledHour = hour;
    scheduledMinute = minute;
    this.title = title;
  }
}
