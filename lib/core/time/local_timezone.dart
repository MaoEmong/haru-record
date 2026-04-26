import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Future<tz.Location> configureLocalTimezone({
  Future<String> Function()? loadTimeZoneIdentifier,
}) async {
  tzdata.initializeTimeZones();
  final identifier = loadTimeZoneIdentifier == null
      ? (await FlutterTimezone.getLocalTimezone()).identifier
      : await loadTimeZoneIdentifier();
  final location = tz.getLocation(identifier);
  tz.setLocalLocation(location);
  return location;
}
