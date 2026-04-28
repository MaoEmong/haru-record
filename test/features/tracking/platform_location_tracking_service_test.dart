import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/settings/settings_models.dart';
import 'package:projectapp_1/features/tracking/platform_location_tracking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('daily_pattern/tracking');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'isTracking') {
            return false;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('startTracking sends default movement and stay thresholds', () async {
    final service = PlatformLocationTrackingService(channel: channel);

    expect(await service.isTracking(), isFalse);
    await service.startTracking(AppSettings.defaults());

    expect(
      calls,
      contains(
        isA<MethodCall>()
            .having((call) => call.method, 'method', 'startTracking')
            .having((call) => call.arguments, 'arguments', {
              'minimumMovementMeters': 100,
              'minimumStayMinutes': 10,
              'rawLocationIntervalSeconds': 10,
            }),
      ),
    );
  });

  test('startTracking surfaces native start failures', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'startTracking') {
            throw PlatformException(code: 'tracking_start_failed');
          }
          return null;
        });
    final service = PlatformLocationTrackingService(channel: channel);

    await expectLater(
      service.startTracking(AppSettings.defaults()),
      throwsA(isA<PlatformException>()),
    );
  });
}
