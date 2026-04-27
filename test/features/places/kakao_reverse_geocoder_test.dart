import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/places/kakao_reverse_geocoder.dart';

void main() {
  test('parses road and land-lot address from Kakao coord2address', () async {
    final geocoder = KakaoReverseGeocoder(
      restApiKey: 'test-key',
      request: (uri, headers) async {
        expect(uri.host, 'dapi.kakao.com');
        expect(uri.path, '/v2/local/geo/coord2address.json');
        expect(uri.queryParameters['x'], '126.978');
        expect(uri.queryParameters['y'], '37.5665');
        expect(headers['Authorization'], 'KakaoAK test-key');
        return const KakaoHttpResponse(
          statusCode: 200,
          body: '''
{
  "meta": {"total_count": 1},
  "documents": [
    {
      "road_address": {
        "address_name": "서울 중구 세종대로 110"
      },
      "address": {
        "address_name": "서울 중구 태평로1가 31",
        "region_1depth_name": "서울",
        "region_2depth_name": "중구",
        "region_3depth_name": "태평로1가"
      }
    }
  ]
}
''',
        );
      },
    );

    final address = await geocoder.resolve(
      latitude: 37.5665,
      longitude: 126.978,
    );

    expect(address?.roadAddressName, '서울 중구 세종대로 110');
    expect(address?.addressName, '서울 중구 태평로1가 31');
    expect(address?.regionName, '서울 중구 태평로1가');
  });
}
