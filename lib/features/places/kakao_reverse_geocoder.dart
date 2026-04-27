import 'dart:convert';
import 'dart:io';

import 'place_address.dart';

typedef KakaoHttpRequest =
    Future<KakaoHttpResponse> Function(Uri uri, Map<String, String> headers);

class KakaoHttpResponse {
  const KakaoHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

class KakaoReverseGeocoder implements ReverseGeocoder {
  KakaoReverseGeocoder({required String restApiKey, KakaoHttpRequest? request})
    : _restApiKey = restApiKey,
      _request = request ?? _defaultRequest;

  static const _environmentApiKey = String.fromEnvironment(
    'KAKAO_REST_API_KEY',
  );

  final String _restApiKey;
  final KakaoHttpRequest _request;

  static KakaoReverseGeocoder? fromEnvironment() {
    if (_environmentApiKey.isEmpty) return null;
    return KakaoReverseGeocoder(restApiKey: _environmentApiKey);
  }

  @override
  Future<PlaceAddress?> resolve({
    required double latitude,
    required double longitude,
  }) async {
    if (_restApiKey.isEmpty) return null;

    final uri = Uri.https(
      'dapi.kakao.com',
      '/v2/local/geo/coord2address.json',
      {
        'x': longitude.toString(),
        'y': latitude.toString(),
        'input_coord': 'WGS84',
      },
    );
    final response = await _request(uri, {
      'Authorization': 'KakaoAK $_restApiKey',
    });
    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>) return null;
    final documents = decoded['documents'];
    if (documents is! List || documents.isEmpty) return null;
    final first = documents.first;
    if (first is! Map<String, Object?>) return null;

    final roadAddress = first['road_address'];
    final address = first['address'];
    final roadAddressName = _stringField(roadAddress, 'address_name');
    final addressName = _stringField(address, 'address_name');
    final regionName = _regionName(address);

    if (roadAddressName == null && addressName == null && regionName == null) {
      return null;
    }
    return PlaceAddress(
      roadAddressName: roadAddressName,
      addressName: addressName,
      regionName: regionName,
    );
  }

  static String? _stringField(Object? value, String key) {
    if (value is! Map<String, Object?>) return null;
    final field = value[key];
    if (field is! String || field.trim().isEmpty) return null;
    return field.trim();
  }

  static String? _regionName(Object? address) {
    if (address is! Map<String, Object?>) return null;
    final parts = [
      _stringField(address, 'region_1depth_name'),
      _stringField(address, 'region_2depth_name'),
      _stringField(address, 'region_3depth_name'),
    ].whereType<String>().toList(growable: false);
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  static Future<KakaoHttpResponse> _defaultRequest(
    Uri uri,
    Map<String, String> headers,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      for (final entry in headers.entries) {
        request.headers.set(entry.key, entry.value);
      }
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      return KakaoHttpResponse(statusCode: response.statusCode, body: body);
    } finally {
      client.close(force: true);
    }
  }
}
