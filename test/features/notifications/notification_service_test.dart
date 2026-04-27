import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/notifications/notification_service.dart';

void main() {
  test('schedules daily insight notification at configured time', () async {
    final adapter = FakeNotificationAdapter();
    final service = NotificationService(adapter);

    await service.scheduleDailyInsight(hour: 9, minute: 0);

    expect(adapter.scheduledHour, 9);
    expect(adapter.scheduledMinute, 0);
    expect(adapter.title, '어제 하루를 정리했어요');
  });

  test('schedules daily insight notification with generated copy', () async {
    final adapter = FakeNotificationAdapter();
    final service = NotificationService(adapter);

    await service.scheduleDailyInsight(
      hour: 9,
      minute: 0,
      title: '어제는 이동이 평소보다 적었어요',
      body: '저녁 외출이 줄어든 흐름이 보여요.',
    );

    expect(adapter.title, '어제는 이동이 평소보다 적었어요');
    expect(adapter.body, '저녁 외출이 줄어든 흐름이 보여요.');
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

  test('cancels daily insight notification', () async {
    final adapter = FakeNotificationAdapter();
    final service = NotificationService(adapter);

    await service.cancelDailyInsight();

    expect(adapter.cancelledId, NotificationService.dailyInsightNotificationId);
  });

  test('shows a test notification immediately', () async {
    final adapter = FakeNotificationAdapter();
    final service = NotificationService(adapter);

    await service.showTestNotification();

    expect(adapter.shownId, NotificationService.testNotificationId);
    expect(adapter.title, '알림 테스트');
    expect(adapter.body, '이렇게 돌아보기 알림이 도착해요.');
  });
}

class FakeNotificationAdapter implements NotificationAdapter {
  int? scheduledHour;
  int? scheduledMinute;
  String? title;
  String? body;
  int permissionRequestCount = 0;
  int? cancelledId;
  int? shownId;

  @override
  Future<bool?> requestPermission() async {
    permissionRequestCount++;
    return true;
  }

  @override
  Future<void> cancel(int id) async {
    cancelledId = id;
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
    this.body = body;
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    shownId = id;
    this.title = title;
    this.body = body;
  }
}
