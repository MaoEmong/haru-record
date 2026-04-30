import 'dart:developer' as developer;

class AppLogger {
  const AppLogger._();

  static const _name = 'daily_pattern';

  static void warn(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _name,
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
