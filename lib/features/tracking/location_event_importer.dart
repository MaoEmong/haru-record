import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../storage/app_database.dart';

class LocationEventImportResult {
  const LocationEventImportResult({
    required this.importedCount,
    required this.skippedCount,
  });

  final int importedCount;
  final int skippedCount;
}

class LocationEventImporter {
  LocationEventImporter(
    this._database, {
    MethodChannel channel = const MethodChannel('daily_pattern/tracking'),
    Future<void> Function()? afterSnapshot,
  }) : _channel = channel,
       _eventFile = null,
       _afterSnapshot = afterSnapshot;

  LocationEventImporter.fromFile(
    this._database,
    File eventFile, {
    Future<void> Function()? afterSnapshot,
  }) : _channel = null,
       _eventFile = eventFile,
       _afterSnapshot = afterSnapshot;

  final AppDatabase _database;
  final MethodChannel? _channel;
  final File? _eventFile;
  final Future<void> Function()? _afterSnapshot;

  Future<LocationEventImportResult> importPendingEvents() async {
    final file = await _resolveEventFile();
    if (file == null) {
      return const LocationEventImportResult(importedCount: 0, skippedCount: 0);
    }

    final snapshot = File('${file.path}.importing');
    if (!await snapshot.exists()) {
      if (!await file.exists()) {
        return const LocationEventImportResult(
          importedCount: 0,
          skippedCount: 0,
        );
      }
      await file.rename(snapshot.path);
      await _afterSnapshot?.call();
    }

    final lines = await snapshot.readAsLines();
    var imported = 0;
    var skipped = 0;

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      late final _ParsedLocationEvent event;
      try {
        event = _parseEvent(jsonDecode(line) as Map<String, Object?>);
      } catch (_) {
        skipped++;
        continue;
      }

      if (await _alreadyImported(event)) {
        continue;
      }

      await _database
          .into(_database.locationPoints)
          .insert(_companionFromEvent(event));
      imported++;
    }

    await snapshot.delete();
    if (!await file.exists()) {
      await file.writeAsString('');
    }
    return LocationEventImportResult(
      importedCount: imported,
      skippedCount: skipped,
    );
  }

  Future<File?> _resolveEventFile() async {
    if (_eventFile != null) return _eventFile;
    final path = await _channel?.invokeMethod<String>('getEventFilePath');
    if (path == null || path.isEmpty) return null;
    return File(path);
  }

  Future<bool> _alreadyImported(_ParsedLocationEvent event) async {
    final query = _database.select(_database.locationPoints)
      ..where(
        (point) =>
            point.timestamp.equals(event.timestamp) &
            point.latitude.equals(event.latitude) &
            point.longitude.equals(event.longitude) &
            point.accuracy.equals(event.accuracy) &
            point.source.equals(event.source),
      )
      ..limit(1);
    return await query.getSingleOrNull() != null;
  }

  _ParsedLocationEvent _parseEvent(Map<String, Object?> json) {
    return _ParsedLocationEvent(
      timestamp: DateTime.parse(json['timestamp']! as String),
      latitude: _requiredDouble(json['latitude']),
      longitude: _requiredDouble(json['longitude']),
      accuracy: _requiredDouble(json['accuracy']),
      speed: _nullableDouble(json['speed']),
      isMock: json['isMock'] as bool? ?? false,
      source: json['source'] as String? ?? 'android',
    );
  }

  LocationPointsCompanion _companionFromEvent(_ParsedLocationEvent event) {
    return LocationPointsCompanion.insert(
      timestamp: event.timestamp,
      latitude: event.latitude,
      longitude: event.longitude,
      accuracy: event.accuracy,
      speed: Value(event.speed),
      isMock: Value(event.isMock),
      source: Value(event.source),
    );
  }

  double _requiredDouble(Object? value) {
    return (value! as num).toDouble();
  }

  double? _nullableDouble(Object? value) {
    if (value == null) return null;
    return (value as num).toDouble();
  }
}

class _ParsedLocationEvent {
  const _ParsedLocationEvent({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.isMock,
    required this.source,
  });

  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? speed;
  final bool isMock;
  final String source;
}
