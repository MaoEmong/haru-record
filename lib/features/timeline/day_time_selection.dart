import 'day_route_models.dart';
import 'day_timeline_models.dart';

class RoutePlaybackWindow {
  const RoutePlaybackWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  Duration get duration {
    final value = end.difference(start);
    return value.isNegative ? Duration.zero : value;
  }
}

int? nearestRoutePointIndexForProgress(
  List<DayRoutePoint> points,
  double progress,
) {
  if (points.isEmpty) return null;
  final targetSeconds = (progress.clamp(0.0, 1.0) * daySeconds).round();
  var nearestIndex = 0;
  var nearestDelta = (_secondsOfDay(points.first.timestamp) - targetSeconds)
      .abs();
  for (var index = 1; index < points.length; index++) {
    final delta = (_secondsOfDay(points[index].timestamp) - targetSeconds)
        .abs();
    if (delta < nearestDelta) {
      nearestDelta = delta;
      nearestIndex = index;
    }
  }
  return nearestIndex;
}

int? nearestRoutePointIndexForTime(List<DayRoutePoint> points, DateTime time) {
  if (points.isEmpty) return null;
  var nearestIndex = 0;
  var nearestDelta = points.first.timestamp.difference(time).abs();
  for (var index = 1; index < points.length; index++) {
    final delta = points[index].timestamp.difference(time).abs();
    if (delta < nearestDelta) {
      nearestDelta = delta;
      nearestIndex = index;
    }
  }
  return nearestIndex;
}

double progressForTime(DateTime time) {
  return (_secondsOfDay(time) / daySeconds).clamp(0.0, 1.0);
}

DateTime timeFromProgress(DateTime date, double progress) {
  final seconds = (progress.clamp(0.0, 1.0) * daySeconds).round();
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).add(Duration(seconds: seconds));
}

double progressForPlaybackTime(RoutePlaybackWindow window, DateTime time) {
  final duration = window.duration;
  if (duration == Duration.zero) return 1.0;
  final elapsed = time.difference(window.start);
  if (elapsed.isNegative) return 0.0;
  return (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
}

DateTime playbackTimeFromProgress(RoutePlaybackWindow window, double progress) {
  final duration = window.duration;
  if (duration == Duration.zero) return window.start;
  final elapsedMilliseconds =
      (duration.inMilliseconds * progress.clamp(0.0, 1.0)).round();
  return window.start.add(Duration(milliseconds: elapsedMilliseconds));
}

DayRoutePoint interpolateRoutePoint(
  DayRoutePoint start,
  DayRoutePoint end,
  double progress,
) {
  final t = progress.clamp(0.0, 1.0);
  final timestampDelta = end.timestamp.difference(start.timestamp);
  return DayRoutePoint(
    timestamp: start.timestamp.add(
      Duration(milliseconds: (timestampDelta.inMilliseconds * t).round()),
    ),
    timeLabel: t < 0.5 ? start.timeLabel : end.timeLabel,
    latitude: _lerp(start.latitude, end.latitude, t),
    longitude: _lerp(start.longitude, end.longitude, t),
    accuracyMeters: _lerp(start.accuracyMeters, end.accuracyMeters, t),
  );
}

RoutePlaybackWindow? playbackWindowForDate({
  required DateTime date,
  required List<DayRoutePoint> points,
  required DateTime now,
}) {
  if (points.isEmpty) return null;
  final sorted = [...points]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final start = sorted.first.timestamp;
  final last = sorted.last.timestamp;
  final end = _isSameDate(date, now) && now.isAfter(last) ? now : last;
  return RoutePlaybackWindow(
    start: start,
    end: end.isBefore(start) ? start : end,
  );
}

String routeTimeLabel(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

List<DayTimelineItem> timelineItemsAtOrBefore(
  List<DayTimelineItem> items,
  DateTime time,
) {
  return items
      .where((item) {
        final startedAt = item.startedAt;
        if (startedAt == null) return false;
        return !startedAt.isAfter(time);
      })
      .toList(growable: false);
}

DayTimelineItem? timelineItemAt(List<DayTimelineItem> items, DateTime time) {
  for (final item in items.reversed) {
    final startedAt = item.startedAt;
    if (startedAt == null || startedAt.isAfter(time)) continue;
    final endedAt = item.endedAt;
    if (endedAt == null || !endedAt.isBefore(time)) return item;
  }
  return null;
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

int _secondsOfDay(DateTime time) {
  return time.hour * 3600 + time.minute * 60 + time.second;
}

double _lerp(double start, double end, double progress) {
  return start + (end - start) * progress;
}

const daySeconds = 24 * 60 * 60 - 1;
