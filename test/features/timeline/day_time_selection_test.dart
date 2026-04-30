import 'package:flutter_test/flutter_test.dart';
import 'package:projectapp_1/features/timeline/day_route_models.dart';
import 'package:projectapp_1/features/timeline/day_time_selection.dart';

void main() {
  test('playback window uses current time for today', () {
    final date = DateTime(2026, 4, 30);
    final points = [
      _point(DateTime(2026, 4, 30, 7, 30)),
      _point(DateTime(2026, 4, 30, 8)),
    ];

    final window = playbackWindowForDate(
      date: date,
      points: points,
      now: DateTime(2026, 4, 30, 9),
    );

    expect(window?.start, DateTime(2026, 4, 30, 7, 30));
    expect(window?.end, DateTime(2026, 4, 30, 9));
  });

  test('playback window uses last route point for past days', () {
    final date = DateTime(2026, 4, 29);
    final points = [
      _point(DateTime(2026, 4, 29, 7, 30)),
      _point(DateTime(2026, 4, 29, 18)),
    ];

    final window = playbackWindowForDate(
      date: date,
      points: points,
      now: DateTime(2026, 4, 30, 9),
    );

    expect(window?.start, DateTime(2026, 4, 29, 7, 30));
    expect(window?.end, DateTime(2026, 4, 29, 18));
  });

  test('playback progress maps within the recorded window', () {
    final window = RoutePlaybackWindow(
      start: DateTime(2026, 4, 30, 8),
      end: DateTime(2026, 4, 30, 10),
    );

    expect(progressForPlaybackTime(window, DateTime(2026, 4, 30, 9)), 0.5);
    expect(playbackTimeFromProgress(window, 0.5), DateTime(2026, 4, 30, 9));
  });

  test('nearest route point can be selected by time', () {
    final points = [
      _point(DateTime(2026, 4, 30, 8)),
      _point(DateTime(2026, 4, 30, 9)),
      _point(DateTime(2026, 4, 30, 10)),
    ];

    expect(
      nearestRoutePointIndexForTime(points, DateTime(2026, 4, 30, 9, 20)),
      1,
    );
  });

  test('route point interpolation moves smoothly between coordinates', () {
    final start = _point(
      DateTime(2026, 4, 30, 8),
      latitude: 37,
      longitude: 127,
    );
    final end = _point(
      DateTime(2026, 4, 30, 8, 10),
      latitude: 37.01,
      longitude: 127.02,
    );

    final middle = interpolateRoutePoint(start, end, 0.5);

    expect(middle.latitude, closeTo(37.005, 0.000001));
    expect(middle.longitude, closeTo(127.01, 0.000001));
    expect(interpolateRoutePoint(start, end, -1).latitude, start.latitude);
    expect(interpolateRoutePoint(start, end, 2).longitude, end.longitude);
  });
}

DayRoutePoint _point(
  DateTime timestamp, {
  double latitude = 37,
  double longitude = 127,
}) {
  return DayRoutePoint(
    timestamp: timestamp,
    timeLabel: routeTimeLabel(timestamp),
    latitude: latitude,
    longitude: longitude,
    accuracyMeters: 20,
  );
}
