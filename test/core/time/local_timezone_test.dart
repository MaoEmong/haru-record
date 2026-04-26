import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/core/time/local_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test(
    'sets timezone local location from a device timezone identifier',
    () async {
      final location = await configureLocalTimezone(
        loadTimeZoneIdentifier: () async => 'Asia/Seoul',
      );

      expect(location.name, 'Asia/Seoul');
      expect(tz.local.name, 'Asia/Seoul');
    },
  );
}
