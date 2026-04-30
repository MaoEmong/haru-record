import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/core/time/date_key.dart';

void main() {
  test('formats a local date key as yyyy-MM-dd', () {
    expect(dateKey(DateTime(2026, 4, 5, 23, 59)), '2026-04-05');
  });

  test('compares dates without considering time of day', () {
    expect(
      isSameLocalDate(DateTime(2026, 4, 30, 9), DateTime(2026, 4, 30, 23)),
      isTrue,
    );
    expect(
      isSameLocalDate(DateTime(2026, 4, 30), DateTime(2026, 5, 1)),
      isFalse,
    );
  });
}
