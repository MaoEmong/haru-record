import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/main.dart' as app_main;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('locks the app to portrait orientation', () async {
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    addTearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });

    await app_main.lockAppOrientation();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'SystemChrome.setPreferredOrientations');
    expect(calls.single.arguments, ['DeviceOrientation.portraitUp']);
  });
}
