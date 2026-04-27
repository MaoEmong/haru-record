import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  const EnvConfig._();

  static const _dartDefineKakaoRestApiKey = String.fromEnvironment(
    'KAKAO_REST_API_KEY',
  );

  static Future<void> load() async {
    try {
      await dotenv.load();
    } on Object {
      // Local .env is intentionally optional. dart-define remains the fallback.
    }
  }

  static String get kakaoRestApiKey {
    if (_dartDefineKakaoRestApiKey.isNotEmpty) {
      return _dartDefineKakaoRestApiKey;
    }
    try {
      return dotenv.maybeGet('KAKAO_REST_API_KEY')?.trim() ?? '';
    } on Object {
      return '';
    }
  }
}
