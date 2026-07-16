import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release manifest declares INTERNET permission', () {
    // debug/profile 매니페스트는 Flutter가 INTERNET을 자동 주입하지만
    // release는 main 매니페스트에 직접 선언해야 한다. 이게 빠지면
    // 지도 타일(OSM)과 카카오 역지오코딩이 release 빌드에서만 조용히 실패한다.
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      manifest.contains('android.permission.INTERNET'),
      isTrue,
      reason: 'main AndroidManifest.xml에 INTERNET 권한이 선언되어야 합니다',
    );
  });
}
