// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocationPointsTable extends LocationPoints
    with TableInfo<$LocationPointsTable, LocationPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isMockMeta = const VerificationMeta('isMock');
  @override
  late final GeneratedColumn<bool> isMock = GeneratedColumn<bool>(
    'is_mock',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_mock" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('android'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    latitude,
    longitude,
    accuracy,
    speed,
    isMock,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'location_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocationPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    } else if (isInserting) {
      context.missing(_accuracyMeta);
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    }
    if (data.containsKey('is_mock')) {
      context.handle(
        _isMockMeta,
        isMock.isAcceptableOrUnknown(data['is_mock']!, _isMockMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocationPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocationPoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      )!,
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      ),
      isMock: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_mock'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $LocationPointsTable createAlias(String alias) {
    return $LocationPointsTable(attachedDatabase, alias);
  }
}

class LocationPoint extends DataClass implements Insertable<LocationPoint> {
  final int id;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? speed;
  final bool isMock;
  final String source;
  const LocationPoint({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.speed,
    required this.isMock,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['accuracy'] = Variable<double>(accuracy);
    if (!nullToAbsent || speed != null) {
      map['speed'] = Variable<double>(speed);
    }
    map['is_mock'] = Variable<bool>(isMock);
    map['source'] = Variable<String>(source);
    return map;
  }

  LocationPointsCompanion toCompanion(bool nullToAbsent) {
    return LocationPointsCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      latitude: Value(latitude),
      longitude: Value(longitude),
      accuracy: Value(accuracy),
      speed: speed == null && nullToAbsent
          ? const Value.absent()
          : Value(speed),
      isMock: Value(isMock),
      source: Value(source),
    );
  }

  factory LocationPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocationPoint(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      accuracy: serializer.fromJson<double>(json['accuracy']),
      speed: serializer.fromJson<double?>(json['speed']),
      isMock: serializer.fromJson<bool>(json['isMock']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'accuracy': serializer.toJson<double>(accuracy),
      'speed': serializer.toJson<double?>(speed),
      'isMock': serializer.toJson<bool>(isMock),
      'source': serializer.toJson<String>(source),
    };
  }

  LocationPoint copyWith({
    int? id,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    double? accuracy,
    Value<double?> speed = const Value.absent(),
    bool? isMock,
    String? source,
  }) => LocationPoint(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    accuracy: accuracy ?? this.accuracy,
    speed: speed.present ? speed.value : this.speed,
    isMock: isMock ?? this.isMock,
    source: source ?? this.source,
  );
  LocationPoint copyWithCompanion(LocationPointsCompanion data) {
    return LocationPoint(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      speed: data.speed.present ? data.speed.value : this.speed,
      isMock: data.isMock.present ? data.isMock.value : this.isMock,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocationPoint(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('speed: $speed, ')
          ..write('isMock: $isMock, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    timestamp,
    latitude,
    longitude,
    accuracy,
    speed,
    isMock,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocationPoint &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.accuracy == this.accuracy &&
          other.speed == this.speed &&
          other.isMock == this.isMock &&
          other.source == this.source);
}

class LocationPointsCompanion extends UpdateCompanion<LocationPoint> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> accuracy;
  final Value<double?> speed;
  final Value<bool> isMock;
  final Value<String> source;
  const LocationPointsCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.speed = const Value.absent(),
    this.isMock = const Value.absent(),
    this.source = const Value.absent(),
  });
  LocationPointsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime timestamp,
    required double latitude,
    required double longitude,
    required double accuracy,
    this.speed = const Value.absent(),
    this.isMock = const Value.absent(),
    this.source = const Value.absent(),
  }) : timestamp = Value(timestamp),
       latitude = Value(latitude),
       longitude = Value(longitude),
       accuracy = Value(accuracy);
  static Insertable<LocationPoint> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? accuracy,
    Expression<double>? speed,
    Expression<bool>? isMock,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (speed != null) 'speed': speed,
      if (isMock != null) 'is_mock': isMock,
      if (source != null) 'source': source,
    });
  }

  LocationPointsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double>? accuracy,
    Value<double?>? speed,
    Value<bool>? isMock,
    Value<String>? source,
  }) {
    return LocationPointsCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      isMock: isMock ?? this.isMock,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (isMock.present) {
      map['is_mock'] = Variable<bool>(isMock.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationPointsCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('speed: $speed, ')
          ..write('isMock: $isMock, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $PlaceClustersTable extends PlaceClusters
    with TableInfo<$PlaceClustersTable, PlaceCluster> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaceClustersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _centerLatitudeMeta = const VerificationMeta(
    'centerLatitude',
  );
  @override
  late final GeneratedColumn<double> centerLatitude = GeneratedColumn<double>(
    'center_latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _centerLongitudeMeta = const VerificationMeta(
    'centerLongitude',
  );
  @override
  late final GeneratedColumn<double> centerLongitude = GeneratedColumn<double>(
    'center_longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _radiusMetersMeta = const VerificationMeta(
    'radiusMeters',
  );
  @override
  late final GeneratedColumn<double> radiusMeters = GeneratedColumn<double>(
    'radius_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressNameMeta = const VerificationMeta(
    'addressName',
  );
  @override
  late final GeneratedColumn<String> addressName = GeneratedColumn<String>(
    'address_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roadAddressNameMeta = const VerificationMeta(
    'roadAddressName',
  );
  @override
  late final GeneratedColumn<String> roadAddressName = GeneratedColumn<String>(
    'road_address_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _regionNameMeta = const VerificationMeta(
    'regionName',
  );
  @override
  late final GeneratedColumn<String> regionName = GeneratedColumn<String>(
    'region_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressResolvedAtMeta = const VerificationMeta(
    'addressResolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addressResolvedAt =
      GeneratedColumn<DateTime>(
        'address_resolved_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitCountMeta = const VerificationMeta(
    'visitCount',
  );
  @override
  late final GeneratedColumn<int> visitCount = GeneratedColumn<int>(
    'visit_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    centerLatitude,
    centerLongitude,
    radiusMeters,
    displayName,
    addressName,
    roadAddressName,
    regionName,
    addressResolvedAt,
    photoPath,
    createdAt,
    updatedAt,
    visitCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'place_clusters';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaceCluster> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('center_latitude')) {
      context.handle(
        _centerLatitudeMeta,
        centerLatitude.isAcceptableOrUnknown(
          data['center_latitude']!,
          _centerLatitudeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_centerLatitudeMeta);
    }
    if (data.containsKey('center_longitude')) {
      context.handle(
        _centerLongitudeMeta,
        centerLongitude.isAcceptableOrUnknown(
          data['center_longitude']!,
          _centerLongitudeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_centerLongitudeMeta);
    }
    if (data.containsKey('radius_meters')) {
      context.handle(
        _radiusMetersMeta,
        radiusMeters.isAcceptableOrUnknown(
          data['radius_meters']!,
          _radiusMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_radiusMetersMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('address_name')) {
      context.handle(
        _addressNameMeta,
        addressName.isAcceptableOrUnknown(
          data['address_name']!,
          _addressNameMeta,
        ),
      );
    }
    if (data.containsKey('road_address_name')) {
      context.handle(
        _roadAddressNameMeta,
        roadAddressName.isAcceptableOrUnknown(
          data['road_address_name']!,
          _roadAddressNameMeta,
        ),
      );
    }
    if (data.containsKey('region_name')) {
      context.handle(
        _regionNameMeta,
        regionName.isAcceptableOrUnknown(data['region_name']!, _regionNameMeta),
      );
    }
    if (data.containsKey('address_resolved_at')) {
      context.handle(
        _addressResolvedAtMeta,
        addressResolvedAt.isAcceptableOrUnknown(
          data['address_resolved_at']!,
          _addressResolvedAtMeta,
        ),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('visit_count')) {
      context.handle(
        _visitCountMeta,
        visitCount.isAcceptableOrUnknown(data['visit_count']!, _visitCountMeta),
      );
    } else if (isInserting) {
      context.missing(_visitCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaceCluster map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaceCluster(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      centerLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}center_latitude'],
      )!,
      centerLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}center_longitude'],
      )!,
      radiusMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}radius_meters'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      addressName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address_name'],
      ),
      roadAddressName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}road_address_name'],
      ),
      regionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region_name'],
      ),
      addressResolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}address_resolved_at'],
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      visitCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}visit_count'],
      )!,
    );
  }

  @override
  $PlaceClustersTable createAlias(String alias) {
    return $PlaceClustersTable(attachedDatabase, alias);
  }
}

class PlaceCluster extends DataClass implements Insertable<PlaceCluster> {
  final int id;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusMeters;
  final String? displayName;
  final String? addressName;
  final String? roadAddressName;
  final String? regionName;
  final DateTime? addressResolvedAt;

  /// v3에서 장소당 사진 1장을 담던 컬럼. v4부터 PlacePhotos 테이블이
  /// 대체하며, 기존 값은 마이그레이션으로 옮겨진다. 읽지 말 것.
  final String? photoPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int visitCount;
  const PlaceCluster({
    required this.id,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusMeters,
    this.displayName,
    this.addressName,
    this.roadAddressName,
    this.regionName,
    this.addressResolvedAt,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
    required this.visitCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['center_latitude'] = Variable<double>(centerLatitude);
    map['center_longitude'] = Variable<double>(centerLongitude);
    map['radius_meters'] = Variable<double>(radiusMeters);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || addressName != null) {
      map['address_name'] = Variable<String>(addressName);
    }
    if (!nullToAbsent || roadAddressName != null) {
      map['road_address_name'] = Variable<String>(roadAddressName);
    }
    if (!nullToAbsent || regionName != null) {
      map['region_name'] = Variable<String>(regionName);
    }
    if (!nullToAbsent || addressResolvedAt != null) {
      map['address_resolved_at'] = Variable<DateTime>(addressResolvedAt);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['visit_count'] = Variable<int>(visitCount);
    return map;
  }

  PlaceClustersCompanion toCompanion(bool nullToAbsent) {
    return PlaceClustersCompanion(
      id: Value(id),
      centerLatitude: Value(centerLatitude),
      centerLongitude: Value(centerLongitude),
      radiusMeters: Value(radiusMeters),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      addressName: addressName == null && nullToAbsent
          ? const Value.absent()
          : Value(addressName),
      roadAddressName: roadAddressName == null && nullToAbsent
          ? const Value.absent()
          : Value(roadAddressName),
      regionName: regionName == null && nullToAbsent
          ? const Value.absent()
          : Value(regionName),
      addressResolvedAt: addressResolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(addressResolvedAt),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      visitCount: Value(visitCount),
    );
  }

  factory PlaceCluster.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaceCluster(
      id: serializer.fromJson<int>(json['id']),
      centerLatitude: serializer.fromJson<double>(json['centerLatitude']),
      centerLongitude: serializer.fromJson<double>(json['centerLongitude']),
      radiusMeters: serializer.fromJson<double>(json['radiusMeters']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      addressName: serializer.fromJson<String?>(json['addressName']),
      roadAddressName: serializer.fromJson<String?>(json['roadAddressName']),
      regionName: serializer.fromJson<String?>(json['regionName']),
      addressResolvedAt: serializer.fromJson<DateTime?>(
        json['addressResolvedAt'],
      ),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      visitCount: serializer.fromJson<int>(json['visitCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'centerLatitude': serializer.toJson<double>(centerLatitude),
      'centerLongitude': serializer.toJson<double>(centerLongitude),
      'radiusMeters': serializer.toJson<double>(radiusMeters),
      'displayName': serializer.toJson<String?>(displayName),
      'addressName': serializer.toJson<String?>(addressName),
      'roadAddressName': serializer.toJson<String?>(roadAddressName),
      'regionName': serializer.toJson<String?>(regionName),
      'addressResolvedAt': serializer.toJson<DateTime?>(addressResolvedAt),
      'photoPath': serializer.toJson<String?>(photoPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'visitCount': serializer.toJson<int>(visitCount),
    };
  }

  PlaceCluster copyWith({
    int? id,
    double? centerLatitude,
    double? centerLongitude,
    double? radiusMeters,
    Value<String?> displayName = const Value.absent(),
    Value<String?> addressName = const Value.absent(),
    Value<String?> roadAddressName = const Value.absent(),
    Value<String?> regionName = const Value.absent(),
    Value<DateTime?> addressResolvedAt = const Value.absent(),
    Value<String?> photoPath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    int? visitCount,
  }) => PlaceCluster(
    id: id ?? this.id,
    centerLatitude: centerLatitude ?? this.centerLatitude,
    centerLongitude: centerLongitude ?? this.centerLongitude,
    radiusMeters: radiusMeters ?? this.radiusMeters,
    displayName: displayName.present ? displayName.value : this.displayName,
    addressName: addressName.present ? addressName.value : this.addressName,
    roadAddressName: roadAddressName.present
        ? roadAddressName.value
        : this.roadAddressName,
    regionName: regionName.present ? regionName.value : this.regionName,
    addressResolvedAt: addressResolvedAt.present
        ? addressResolvedAt.value
        : this.addressResolvedAt,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    visitCount: visitCount ?? this.visitCount,
  );
  PlaceCluster copyWithCompanion(PlaceClustersCompanion data) {
    return PlaceCluster(
      id: data.id.present ? data.id.value : this.id,
      centerLatitude: data.centerLatitude.present
          ? data.centerLatitude.value
          : this.centerLatitude,
      centerLongitude: data.centerLongitude.present
          ? data.centerLongitude.value
          : this.centerLongitude,
      radiusMeters: data.radiusMeters.present
          ? data.radiusMeters.value
          : this.radiusMeters,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      addressName: data.addressName.present
          ? data.addressName.value
          : this.addressName,
      roadAddressName: data.roadAddressName.present
          ? data.roadAddressName.value
          : this.roadAddressName,
      regionName: data.regionName.present
          ? data.regionName.value
          : this.regionName,
      addressResolvedAt: data.addressResolvedAt.present
          ? data.addressResolvedAt.value
          : this.addressResolvedAt,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      visitCount: data.visitCount.present
          ? data.visitCount.value
          : this.visitCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaceCluster(')
          ..write('id: $id, ')
          ..write('centerLatitude: $centerLatitude, ')
          ..write('centerLongitude: $centerLongitude, ')
          ..write('radiusMeters: $radiusMeters, ')
          ..write('displayName: $displayName, ')
          ..write('addressName: $addressName, ')
          ..write('roadAddressName: $roadAddressName, ')
          ..write('regionName: $regionName, ')
          ..write('addressResolvedAt: $addressResolvedAt, ')
          ..write('photoPath: $photoPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('visitCount: $visitCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    centerLatitude,
    centerLongitude,
    radiusMeters,
    displayName,
    addressName,
    roadAddressName,
    regionName,
    addressResolvedAt,
    photoPath,
    createdAt,
    updatedAt,
    visitCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaceCluster &&
          other.id == this.id &&
          other.centerLatitude == this.centerLatitude &&
          other.centerLongitude == this.centerLongitude &&
          other.radiusMeters == this.radiusMeters &&
          other.displayName == this.displayName &&
          other.addressName == this.addressName &&
          other.roadAddressName == this.roadAddressName &&
          other.regionName == this.regionName &&
          other.addressResolvedAt == this.addressResolvedAt &&
          other.photoPath == this.photoPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.visitCount == this.visitCount);
}

class PlaceClustersCompanion extends UpdateCompanion<PlaceCluster> {
  final Value<int> id;
  final Value<double> centerLatitude;
  final Value<double> centerLongitude;
  final Value<double> radiusMeters;
  final Value<String?> displayName;
  final Value<String?> addressName;
  final Value<String?> roadAddressName;
  final Value<String?> regionName;
  final Value<DateTime?> addressResolvedAt;
  final Value<String?> photoPath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> visitCount;
  const PlaceClustersCompanion({
    this.id = const Value.absent(),
    this.centerLatitude = const Value.absent(),
    this.centerLongitude = const Value.absent(),
    this.radiusMeters = const Value.absent(),
    this.displayName = const Value.absent(),
    this.addressName = const Value.absent(),
    this.roadAddressName = const Value.absent(),
    this.regionName = const Value.absent(),
    this.addressResolvedAt = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.visitCount = const Value.absent(),
  });
  PlaceClustersCompanion.insert({
    this.id = const Value.absent(),
    required double centerLatitude,
    required double centerLongitude,
    required double radiusMeters,
    this.displayName = const Value.absent(),
    this.addressName = const Value.absent(),
    this.roadAddressName = const Value.absent(),
    this.regionName = const Value.absent(),
    this.addressResolvedAt = const Value.absent(),
    this.photoPath = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    required int visitCount,
  }) : centerLatitude = Value(centerLatitude),
       centerLongitude = Value(centerLongitude),
       radiusMeters = Value(radiusMeters),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       visitCount = Value(visitCount);
  static Insertable<PlaceCluster> custom({
    Expression<int>? id,
    Expression<double>? centerLatitude,
    Expression<double>? centerLongitude,
    Expression<double>? radiusMeters,
    Expression<String>? displayName,
    Expression<String>? addressName,
    Expression<String>? roadAddressName,
    Expression<String>? regionName,
    Expression<DateTime>? addressResolvedAt,
    Expression<String>? photoPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? visitCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (centerLatitude != null) 'center_latitude': centerLatitude,
      if (centerLongitude != null) 'center_longitude': centerLongitude,
      if (radiusMeters != null) 'radius_meters': radiusMeters,
      if (displayName != null) 'display_name': displayName,
      if (addressName != null) 'address_name': addressName,
      if (roadAddressName != null) 'road_address_name': roadAddressName,
      if (regionName != null) 'region_name': regionName,
      if (addressResolvedAt != null) 'address_resolved_at': addressResolvedAt,
      if (photoPath != null) 'photo_path': photoPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (visitCount != null) 'visit_count': visitCount,
    });
  }

  PlaceClustersCompanion copyWith({
    Value<int>? id,
    Value<double>? centerLatitude,
    Value<double>? centerLongitude,
    Value<double>? radiusMeters,
    Value<String?>? displayName,
    Value<String?>? addressName,
    Value<String?>? roadAddressName,
    Value<String?>? regionName,
    Value<DateTime?>? addressResolvedAt,
    Value<String?>? photoPath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? visitCount,
  }) {
    return PlaceClustersCompanion(
      id: id ?? this.id,
      centerLatitude: centerLatitude ?? this.centerLatitude,
      centerLongitude: centerLongitude ?? this.centerLongitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      displayName: displayName ?? this.displayName,
      addressName: addressName ?? this.addressName,
      roadAddressName: roadAddressName ?? this.roadAddressName,
      regionName: regionName ?? this.regionName,
      addressResolvedAt: addressResolvedAt ?? this.addressResolvedAt,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      visitCount: visitCount ?? this.visitCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (centerLatitude.present) {
      map['center_latitude'] = Variable<double>(centerLatitude.value);
    }
    if (centerLongitude.present) {
      map['center_longitude'] = Variable<double>(centerLongitude.value);
    }
    if (radiusMeters.present) {
      map['radius_meters'] = Variable<double>(radiusMeters.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (addressName.present) {
      map['address_name'] = Variable<String>(addressName.value);
    }
    if (roadAddressName.present) {
      map['road_address_name'] = Variable<String>(roadAddressName.value);
    }
    if (regionName.present) {
      map['region_name'] = Variable<String>(regionName.value);
    }
    if (addressResolvedAt.present) {
      map['address_resolved_at'] = Variable<DateTime>(addressResolvedAt.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (visitCount.present) {
      map['visit_count'] = Variable<int>(visitCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaceClustersCompanion(')
          ..write('id: $id, ')
          ..write('centerLatitude: $centerLatitude, ')
          ..write('centerLongitude: $centerLongitude, ')
          ..write('radiusMeters: $radiusMeters, ')
          ..write('displayName: $displayName, ')
          ..write('addressName: $addressName, ')
          ..write('roadAddressName: $roadAddressName, ')
          ..write('regionName: $regionName, ')
          ..write('addressResolvedAt: $addressResolvedAt, ')
          ..write('photoPath: $photoPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('visitCount: $visitCount')
          ..write(')'))
        .toString();
  }
}

class $VisitsTable extends Visits with TableInfo<$VisitsTable, Visit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _placeClusterIdMeta = const VerificationMeta(
    'placeClusterId',
  );
  @override
  late final GeneratedColumn<int> placeClusterId = GeneratedColumn<int>(
    'place_cluster_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES place_clusters (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _representativeLatitudeMeta =
      const VerificationMeta('representativeLatitude');
  @override
  late final GeneratedColumn<double> representativeLatitude =
      GeneratedColumn<double>(
        'representative_latitude',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _representativeLongitudeMeta =
      const VerificationMeta('representativeLongitude');
  @override
  late final GeneratedColumn<double> representativeLongitude =
      GeneratedColumn<double>(
        'representative_longitude',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    placeClusterId,
    startedAt,
    endedAt,
    durationMinutes,
    representativeLatitude,
    representativeLongitude,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Visit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('place_cluster_id')) {
      context.handle(
        _placeClusterIdMeta,
        placeClusterId.isAcceptableOrUnknown(
          data['place_cluster_id']!,
          _placeClusterIdMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('representative_latitude')) {
      context.handle(
        _representativeLatitudeMeta,
        representativeLatitude.isAcceptableOrUnknown(
          data['representative_latitude']!,
          _representativeLatitudeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_representativeLatitudeMeta);
    }
    if (data.containsKey('representative_longitude')) {
      context.handle(
        _representativeLongitudeMeta,
        representativeLongitude.isAcceptableOrUnknown(
          data['representative_longitude']!,
          _representativeLongitudeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_representativeLongitudeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Visit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Visit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      placeClusterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}place_cluster_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      representativeLatitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}representative_latitude'],
      )!,
      representativeLongitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}representative_longitude'],
      )!,
    );
  }

  @override
  $VisitsTable createAlias(String alias) {
    return $VisitsTable(attachedDatabase, alias);
  }
}

class Visit extends DataClass implements Insertable<Visit> {
  final int id;
  final int? placeClusterId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationMinutes;
  final double representativeLatitude;
  final double representativeLongitude;
  const Visit({
    required this.id,
    this.placeClusterId,
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
    required this.representativeLatitude,
    required this.representativeLongitude,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || placeClusterId != null) {
      map['place_cluster_id'] = Variable<int>(placeClusterId);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['representative_latitude'] = Variable<double>(representativeLatitude);
    map['representative_longitude'] = Variable<double>(representativeLongitude);
    return map;
  }

  VisitsCompanion toCompanion(bool nullToAbsent) {
    return VisitsCompanion(
      id: Value(id),
      placeClusterId: placeClusterId == null && nullToAbsent
          ? const Value.absent()
          : Value(placeClusterId),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      durationMinutes: Value(durationMinutes),
      representativeLatitude: Value(representativeLatitude),
      representativeLongitude: Value(representativeLongitude),
    );
  }

  factory Visit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Visit(
      id: serializer.fromJson<int>(json['id']),
      placeClusterId: serializer.fromJson<int?>(json['placeClusterId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      representativeLatitude: serializer.fromJson<double>(
        json['representativeLatitude'],
      ),
      representativeLongitude: serializer.fromJson<double>(
        json['representativeLongitude'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'placeClusterId': serializer.toJson<int?>(placeClusterId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'representativeLatitude': serializer.toJson<double>(
        representativeLatitude,
      ),
      'representativeLongitude': serializer.toJson<double>(
        representativeLongitude,
      ),
    };
  }

  Visit copyWith({
    int? id,
    Value<int?> placeClusterId = const Value.absent(),
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMinutes,
    double? representativeLatitude,
    double? representativeLongitude,
  }) => Visit(
    id: id ?? this.id,
    placeClusterId: placeClusterId.present
        ? placeClusterId.value
        : this.placeClusterId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    representativeLatitude:
        representativeLatitude ?? this.representativeLatitude,
    representativeLongitude:
        representativeLongitude ?? this.representativeLongitude,
  );
  Visit copyWithCompanion(VisitsCompanion data) {
    return Visit(
      id: data.id.present ? data.id.value : this.id,
      placeClusterId: data.placeClusterId.present
          ? data.placeClusterId.value
          : this.placeClusterId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      representativeLatitude: data.representativeLatitude.present
          ? data.representativeLatitude.value
          : this.representativeLatitude,
      representativeLongitude: data.representativeLongitude.present
          ? data.representativeLongitude.value
          : this.representativeLongitude,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Visit(')
          ..write('id: $id, ')
          ..write('placeClusterId: $placeClusterId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('representativeLatitude: $representativeLatitude, ')
          ..write('representativeLongitude: $representativeLongitude')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    placeClusterId,
    startedAt,
    endedAt,
    durationMinutes,
    representativeLatitude,
    representativeLongitude,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Visit &&
          other.id == this.id &&
          other.placeClusterId == this.placeClusterId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationMinutes == this.durationMinutes &&
          other.representativeLatitude == this.representativeLatitude &&
          other.representativeLongitude == this.representativeLongitude);
}

class VisitsCompanion extends UpdateCompanion<Visit> {
  final Value<int> id;
  final Value<int?> placeClusterId;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<int> durationMinutes;
  final Value<double> representativeLatitude;
  final Value<double> representativeLongitude;
  const VisitsCompanion({
    this.id = const Value.absent(),
    this.placeClusterId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.representativeLatitude = const Value.absent(),
    this.representativeLongitude = const Value.absent(),
  });
  VisitsCompanion.insert({
    this.id = const Value.absent(),
    this.placeClusterId = const Value.absent(),
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationMinutes,
    required double representativeLatitude,
    required double representativeLongitude,
  }) : startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       durationMinutes = Value(durationMinutes),
       representativeLatitude = Value(representativeLatitude),
       representativeLongitude = Value(representativeLongitude);
  static Insertable<Visit> custom({
    Expression<int>? id,
    Expression<int>? placeClusterId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? durationMinutes,
    Expression<double>? representativeLatitude,
    Expression<double>? representativeLongitude,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (placeClusterId != null) 'place_cluster_id': placeClusterId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (representativeLatitude != null)
        'representative_latitude': representativeLatitude,
      if (representativeLongitude != null)
        'representative_longitude': representativeLongitude,
    });
  }

  VisitsCompanion copyWith({
    Value<int>? id,
    Value<int?>? placeClusterId,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<int>? durationMinutes,
    Value<double>? representativeLatitude,
    Value<double>? representativeLongitude,
  }) {
    return VisitsCompanion(
      id: id ?? this.id,
      placeClusterId: placeClusterId ?? this.placeClusterId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      representativeLatitude:
          representativeLatitude ?? this.representativeLatitude,
      representativeLongitude:
          representativeLongitude ?? this.representativeLongitude,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (placeClusterId.present) {
      map['place_cluster_id'] = Variable<int>(placeClusterId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (representativeLatitude.present) {
      map['representative_latitude'] = Variable<double>(
        representativeLatitude.value,
      );
    }
    if (representativeLongitude.present) {
      map['representative_longitude'] = Variable<double>(
        representativeLongitude.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitsCompanion(')
          ..write('id: $id, ')
          ..write('placeClusterId: $placeClusterId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('representativeLatitude: $representativeLatitude, ')
          ..write('representativeLongitude: $representativeLongitude')
          ..write(')'))
        .toString();
  }
}

class $DailySummariesTable extends DailySummaries
    with TableInfo<$DailySummariesTable, DailySummary> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailySummariesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (date GLOB \'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\')',
  );
  static const VerificationMeta _totalDistanceMetersMeta =
      const VerificationMeta('totalDistanceMeters');
  @override
  late final GeneratedColumn<double> totalDistanceMeters =
      GeneratedColumn<double>(
        'total_distance_meters',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _movingMinutesMeta = const VerificationMeta(
    'movingMinutes',
  );
  @override
  late final GeneratedColumn<int> movingMinutes = GeneratedColumn<int>(
    'moving_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stationaryMinutesMeta = const VerificationMeta(
    'stationaryMinutes',
  );
  @override
  late final GeneratedColumn<int> stationaryMinutes = GeneratedColumn<int>(
    'stationary_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitCountMeta = const VerificationMeta(
    'visitCount',
  );
  @override
  late final GeneratedColumn<int> visitCount = GeneratedColumn<int>(
    'visit_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newPlaceCountMeta = const VerificationMeta(
    'newPlaceCount',
  );
  @override
  late final GeneratedColumn<int> newPlaceCount = GeneratedColumn<int>(
    'new_place_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longestStayPlaceIdMeta =
      const VerificationMeta('longestStayPlaceId');
  @override
  late final GeneratedColumn<int> longestStayPlaceId = GeneratedColumn<int>(
    'longest_stay_place_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES place_clusters (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    totalDistanceMeters,
    movingMinutes,
    stationaryMinutes,
    visitCount,
    newPlaceCount,
    longestStayPlaceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_summaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailySummary> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('total_distance_meters')) {
      context.handle(
        _totalDistanceMetersMeta,
        totalDistanceMeters.isAcceptableOrUnknown(
          data['total_distance_meters']!,
          _totalDistanceMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalDistanceMetersMeta);
    }
    if (data.containsKey('moving_minutes')) {
      context.handle(
        _movingMinutesMeta,
        movingMinutes.isAcceptableOrUnknown(
          data['moving_minutes']!,
          _movingMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movingMinutesMeta);
    }
    if (data.containsKey('stationary_minutes')) {
      context.handle(
        _stationaryMinutesMeta,
        stationaryMinutes.isAcceptableOrUnknown(
          data['stationary_minutes']!,
          _stationaryMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stationaryMinutesMeta);
    }
    if (data.containsKey('visit_count')) {
      context.handle(
        _visitCountMeta,
        visitCount.isAcceptableOrUnknown(data['visit_count']!, _visitCountMeta),
      );
    } else if (isInserting) {
      context.missing(_visitCountMeta);
    }
    if (data.containsKey('new_place_count')) {
      context.handle(
        _newPlaceCountMeta,
        newPlaceCount.isAcceptableOrUnknown(
          data['new_place_count']!,
          _newPlaceCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_newPlaceCountMeta);
    }
    if (data.containsKey('longest_stay_place_id')) {
      context.handle(
        _longestStayPlaceIdMeta,
        longestStayPlaceId.isAcceptableOrUnknown(
          data['longest_stay_place_id']!,
          _longestStayPlaceIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailySummary map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailySummary(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      totalDistanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_distance_meters'],
      )!,
      movingMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moving_minutes'],
      )!,
      stationaryMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stationary_minutes'],
      )!,
      visitCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}visit_count'],
      )!,
      newPlaceCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_place_count'],
      )!,
      longestStayPlaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longest_stay_place_id'],
      ),
    );
  }

  @override
  $DailySummariesTable createAlias(String alias) {
    return $DailySummariesTable(attachedDatabase, alias);
  }
}

class DailySummary extends DataClass implements Insertable<DailySummary> {
  final String date;
  final double totalDistanceMeters;
  final int movingMinutes;
  final int stationaryMinutes;
  final int visitCount;
  final int newPlaceCount;
  final int? longestStayPlaceId;
  const DailySummary({
    required this.date,
    required this.totalDistanceMeters,
    required this.movingMinutes,
    required this.stationaryMinutes,
    required this.visitCount,
    required this.newPlaceCount,
    this.longestStayPlaceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['total_distance_meters'] = Variable<double>(totalDistanceMeters);
    map['moving_minutes'] = Variable<int>(movingMinutes);
    map['stationary_minutes'] = Variable<int>(stationaryMinutes);
    map['visit_count'] = Variable<int>(visitCount);
    map['new_place_count'] = Variable<int>(newPlaceCount);
    if (!nullToAbsent || longestStayPlaceId != null) {
      map['longest_stay_place_id'] = Variable<int>(longestStayPlaceId);
    }
    return map;
  }

  DailySummariesCompanion toCompanion(bool nullToAbsent) {
    return DailySummariesCompanion(
      date: Value(date),
      totalDistanceMeters: Value(totalDistanceMeters),
      movingMinutes: Value(movingMinutes),
      stationaryMinutes: Value(stationaryMinutes),
      visitCount: Value(visitCount),
      newPlaceCount: Value(newPlaceCount),
      longestStayPlaceId: longestStayPlaceId == null && nullToAbsent
          ? const Value.absent()
          : Value(longestStayPlaceId),
    );
  }

  factory DailySummary.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailySummary(
      date: serializer.fromJson<String>(json['date']),
      totalDistanceMeters: serializer.fromJson<double>(
        json['totalDistanceMeters'],
      ),
      movingMinutes: serializer.fromJson<int>(json['movingMinutes']),
      stationaryMinutes: serializer.fromJson<int>(json['stationaryMinutes']),
      visitCount: serializer.fromJson<int>(json['visitCount']),
      newPlaceCount: serializer.fromJson<int>(json['newPlaceCount']),
      longestStayPlaceId: serializer.fromJson<int?>(json['longestStayPlaceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'totalDistanceMeters': serializer.toJson<double>(totalDistanceMeters),
      'movingMinutes': serializer.toJson<int>(movingMinutes),
      'stationaryMinutes': serializer.toJson<int>(stationaryMinutes),
      'visitCount': serializer.toJson<int>(visitCount),
      'newPlaceCount': serializer.toJson<int>(newPlaceCount),
      'longestStayPlaceId': serializer.toJson<int?>(longestStayPlaceId),
    };
  }

  DailySummary copyWith({
    String? date,
    double? totalDistanceMeters,
    int? movingMinutes,
    int? stationaryMinutes,
    int? visitCount,
    int? newPlaceCount,
    Value<int?> longestStayPlaceId = const Value.absent(),
  }) => DailySummary(
    date: date ?? this.date,
    totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
    movingMinutes: movingMinutes ?? this.movingMinutes,
    stationaryMinutes: stationaryMinutes ?? this.stationaryMinutes,
    visitCount: visitCount ?? this.visitCount,
    newPlaceCount: newPlaceCount ?? this.newPlaceCount,
    longestStayPlaceId: longestStayPlaceId.present
        ? longestStayPlaceId.value
        : this.longestStayPlaceId,
  );
  DailySummary copyWithCompanion(DailySummariesCompanion data) {
    return DailySummary(
      date: data.date.present ? data.date.value : this.date,
      totalDistanceMeters: data.totalDistanceMeters.present
          ? data.totalDistanceMeters.value
          : this.totalDistanceMeters,
      movingMinutes: data.movingMinutes.present
          ? data.movingMinutes.value
          : this.movingMinutes,
      stationaryMinutes: data.stationaryMinutes.present
          ? data.stationaryMinutes.value
          : this.stationaryMinutes,
      visitCount: data.visitCount.present
          ? data.visitCount.value
          : this.visitCount,
      newPlaceCount: data.newPlaceCount.present
          ? data.newPlaceCount.value
          : this.newPlaceCount,
      longestStayPlaceId: data.longestStayPlaceId.present
          ? data.longestStayPlaceId.value
          : this.longestStayPlaceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailySummary(')
          ..write('date: $date, ')
          ..write('totalDistanceMeters: $totalDistanceMeters, ')
          ..write('movingMinutes: $movingMinutes, ')
          ..write('stationaryMinutes: $stationaryMinutes, ')
          ..write('visitCount: $visitCount, ')
          ..write('newPlaceCount: $newPlaceCount, ')
          ..write('longestStayPlaceId: $longestStayPlaceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    date,
    totalDistanceMeters,
    movingMinutes,
    stationaryMinutes,
    visitCount,
    newPlaceCount,
    longestStayPlaceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailySummary &&
          other.date == this.date &&
          other.totalDistanceMeters == this.totalDistanceMeters &&
          other.movingMinutes == this.movingMinutes &&
          other.stationaryMinutes == this.stationaryMinutes &&
          other.visitCount == this.visitCount &&
          other.newPlaceCount == this.newPlaceCount &&
          other.longestStayPlaceId == this.longestStayPlaceId);
}

class DailySummariesCompanion extends UpdateCompanion<DailySummary> {
  final Value<String> date;
  final Value<double> totalDistanceMeters;
  final Value<int> movingMinutes;
  final Value<int> stationaryMinutes;
  final Value<int> visitCount;
  final Value<int> newPlaceCount;
  final Value<int?> longestStayPlaceId;
  final Value<int> rowid;
  const DailySummariesCompanion({
    this.date = const Value.absent(),
    this.totalDistanceMeters = const Value.absent(),
    this.movingMinutes = const Value.absent(),
    this.stationaryMinutes = const Value.absent(),
    this.visitCount = const Value.absent(),
    this.newPlaceCount = const Value.absent(),
    this.longestStayPlaceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailySummariesCompanion.insert({
    required String date,
    required double totalDistanceMeters,
    required int movingMinutes,
    required int stationaryMinutes,
    required int visitCount,
    required int newPlaceCount,
    this.longestStayPlaceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       totalDistanceMeters = Value(totalDistanceMeters),
       movingMinutes = Value(movingMinutes),
       stationaryMinutes = Value(stationaryMinutes),
       visitCount = Value(visitCount),
       newPlaceCount = Value(newPlaceCount);
  static Insertable<DailySummary> custom({
    Expression<String>? date,
    Expression<double>? totalDistanceMeters,
    Expression<int>? movingMinutes,
    Expression<int>? stationaryMinutes,
    Expression<int>? visitCount,
    Expression<int>? newPlaceCount,
    Expression<int>? longestStayPlaceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (totalDistanceMeters != null)
        'total_distance_meters': totalDistanceMeters,
      if (movingMinutes != null) 'moving_minutes': movingMinutes,
      if (stationaryMinutes != null) 'stationary_minutes': stationaryMinutes,
      if (visitCount != null) 'visit_count': visitCount,
      if (newPlaceCount != null) 'new_place_count': newPlaceCount,
      if (longestStayPlaceId != null)
        'longest_stay_place_id': longestStayPlaceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailySummariesCompanion copyWith({
    Value<String>? date,
    Value<double>? totalDistanceMeters,
    Value<int>? movingMinutes,
    Value<int>? stationaryMinutes,
    Value<int>? visitCount,
    Value<int>? newPlaceCount,
    Value<int?>? longestStayPlaceId,
    Value<int>? rowid,
  }) {
    return DailySummariesCompanion(
      date: date ?? this.date,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      movingMinutes: movingMinutes ?? this.movingMinutes,
      stationaryMinutes: stationaryMinutes ?? this.stationaryMinutes,
      visitCount: visitCount ?? this.visitCount,
      newPlaceCount: newPlaceCount ?? this.newPlaceCount,
      longestStayPlaceId: longestStayPlaceId ?? this.longestStayPlaceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (totalDistanceMeters.present) {
      map['total_distance_meters'] = Variable<double>(
        totalDistanceMeters.value,
      );
    }
    if (movingMinutes.present) {
      map['moving_minutes'] = Variable<int>(movingMinutes.value);
    }
    if (stationaryMinutes.present) {
      map['stationary_minutes'] = Variable<int>(stationaryMinutes.value);
    }
    if (visitCount.present) {
      map['visit_count'] = Variable<int>(visitCount.value);
    }
    if (newPlaceCount.present) {
      map['new_place_count'] = Variable<int>(newPlaceCount.value);
    }
    if (longestStayPlaceId.present) {
      map['longest_stay_place_id'] = Variable<int>(longestStayPlaceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailySummariesCompanion(')
          ..write('date: $date, ')
          ..write('totalDistanceMeters: $totalDistanceMeters, ')
          ..write('movingMinutes: $movingMinutes, ')
          ..write('stationaryMinutes: $stationaryMinutes, ')
          ..write('visitCount: $visitCount, ')
          ..write('newPlaceCount: $newPlaceCount, ')
          ..write('longestStayPlaceId: $longestStayPlaceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InsightsTable extends Insights with TableInfo<$InsightsTable, Insight> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InsightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evidenceMeta = const VerificationMeta(
    'evidence',
  );
  @override
  late final GeneratedColumn<String> evidence = GeneratedColumn<String>(
    'evidence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    type,
    severity,
    title,
    body,
    evidence,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'insights';
  @override
  VerificationContext validateIntegrity(
    Insertable<Insight> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('evidence')) {
      context.handle(
        _evidenceMeta,
        evidence.isAcceptableOrUnknown(data['evidence']!, _evidenceMeta),
      );
    } else if (isInserting) {
      context.missing(_evidenceMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Insight map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Insight(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      evidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $InsightsTable createAlias(String alias) {
    return $InsightsTable(attachedDatabase, alias);
  }
}

class Insight extends DataClass implements Insertable<Insight> {
  final int id;
  final DateTime date;
  final String type;
  final String severity;
  final String title;
  final String body;
  final String evidence;
  final DateTime createdAt;
  const Insight({
    required this.id,
    required this.date,
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
    required this.evidence,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<DateTime>(date);
    map['type'] = Variable<String>(type);
    map['severity'] = Variable<String>(severity);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['evidence'] = Variable<String>(evidence);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  InsightsCompanion toCompanion(bool nullToAbsent) {
    return InsightsCompanion(
      id: Value(id),
      date: Value(date),
      type: Value(type),
      severity: Value(severity),
      title: Value(title),
      body: Value(body),
      evidence: Value(evidence),
      createdAt: Value(createdAt),
    );
  }

  factory Insight.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Insight(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      type: serializer.fromJson<String>(json['type']),
      severity: serializer.fromJson<String>(json['severity']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      evidence: serializer.fromJson<String>(json['evidence']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<DateTime>(date),
      'type': serializer.toJson<String>(type),
      'severity': serializer.toJson<String>(severity),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'evidence': serializer.toJson<String>(evidence),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Insight copyWith({
    int? id,
    DateTime? date,
    String? type,
    String? severity,
    String? title,
    String? body,
    String? evidence,
    DateTime? createdAt,
  }) => Insight(
    id: id ?? this.id,
    date: date ?? this.date,
    type: type ?? this.type,
    severity: severity ?? this.severity,
    title: title ?? this.title,
    body: body ?? this.body,
    evidence: evidence ?? this.evidence,
    createdAt: createdAt ?? this.createdAt,
  );
  Insight copyWithCompanion(InsightsCompanion data) {
    return Insight(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      type: data.type.present ? data.type.value : this.type,
      severity: data.severity.present ? data.severity.value : this.severity,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      evidence: data.evidence.present ? data.evidence.value : this.evidence,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Insight(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('evidence: $evidence, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, type, severity, title, body, evidence, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Insight &&
          other.id == this.id &&
          other.date == this.date &&
          other.type == this.type &&
          other.severity == this.severity &&
          other.title == this.title &&
          other.body == this.body &&
          other.evidence == this.evidence &&
          other.createdAt == this.createdAt);
}

class InsightsCompanion extends UpdateCompanion<Insight> {
  final Value<int> id;
  final Value<DateTime> date;
  final Value<String> type;
  final Value<String> severity;
  final Value<String> title;
  final Value<String> body;
  final Value<String> evidence;
  final Value<DateTime> createdAt;
  const InsightsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.type = const Value.absent(),
    this.severity = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.evidence = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  InsightsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime date,
    required String type,
    required String severity,
    required String title,
    required String body,
    required String evidence,
    required DateTime createdAt,
  }) : date = Value(date),
       type = Value(type),
       severity = Value(severity),
       title = Value(title),
       body = Value(body),
       evidence = Value(evidence),
       createdAt = Value(createdAt);
  static Insertable<Insight> custom({
    Expression<int>? id,
    Expression<DateTime>? date,
    Expression<String>? type,
    Expression<String>? severity,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? evidence,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (type != null) 'type': type,
      if (severity != null) 'severity': severity,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (evidence != null) 'evidence': evidence,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  InsightsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? date,
    Value<String>? type,
    Value<String>? severity,
    Value<String>? title,
    Value<String>? body,
    Value<String>? evidence,
    Value<DateTime>? createdAt,
  }) {
    return InsightsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      body: body ?? this.body,
      evidence: evidence ?? this.evidence,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (evidence.present) {
      map['evidence'] = Variable<String>(evidence.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InsightsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('type: $type, ')
          ..write('severity: $severity, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('evidence: $evidence, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PlacePhotosTable extends PlacePhotos
    with TableInfo<$PlacePhotosTable, PlacePhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlacePhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _placeClusterIdMeta = const VerificationMeta(
    'placeClusterId',
  );
  @override
  late final GeneratedColumn<int> placeClusterId = GeneratedColumn<int>(
    'place_cluster_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES place_clusters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    placeClusterId,
    filePath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'place_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlacePhoto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('place_cluster_id')) {
      context.handle(
        _placeClusterIdMeta,
        placeClusterId.isAcceptableOrUnknown(
          data['place_cluster_id']!,
          _placeClusterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_placeClusterIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlacePhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlacePhoto(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      placeClusterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}place_cluster_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlacePhotosTable createAlias(String alias) {
    return $PlacePhotosTable(attachedDatabase, alias);
  }
}

class PlacePhoto extends DataClass implements Insertable<PlacePhoto> {
  final int id;
  final int placeClusterId;
  final String filePath;
  final DateTime createdAt;
  const PlacePhoto({
    required this.id,
    required this.placeClusterId,
    required this.filePath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['place_cluster_id'] = Variable<int>(placeClusterId);
    map['file_path'] = Variable<String>(filePath);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlacePhotosCompanion toCompanion(bool nullToAbsent) {
    return PlacePhotosCompanion(
      id: Value(id),
      placeClusterId: Value(placeClusterId),
      filePath: Value(filePath),
      createdAt: Value(createdAt),
    );
  }

  factory PlacePhoto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlacePhoto(
      id: serializer.fromJson<int>(json['id']),
      placeClusterId: serializer.fromJson<int>(json['placeClusterId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'placeClusterId': serializer.toJson<int>(placeClusterId),
      'filePath': serializer.toJson<String>(filePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlacePhoto copyWith({
    int? id,
    int? placeClusterId,
    String? filePath,
    DateTime? createdAt,
  }) => PlacePhoto(
    id: id ?? this.id,
    placeClusterId: placeClusterId ?? this.placeClusterId,
    filePath: filePath ?? this.filePath,
    createdAt: createdAt ?? this.createdAt,
  );
  PlacePhoto copyWithCompanion(PlacePhotosCompanion data) {
    return PlacePhoto(
      id: data.id.present ? data.id.value : this.id,
      placeClusterId: data.placeClusterId.present
          ? data.placeClusterId.value
          : this.placeClusterId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlacePhoto(')
          ..write('id: $id, ')
          ..write('placeClusterId: $placeClusterId, ')
          ..write('filePath: $filePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, placeClusterId, filePath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlacePhoto &&
          other.id == this.id &&
          other.placeClusterId == this.placeClusterId &&
          other.filePath == this.filePath &&
          other.createdAt == this.createdAt);
}

class PlacePhotosCompanion extends UpdateCompanion<PlacePhoto> {
  final Value<int> id;
  final Value<int> placeClusterId;
  final Value<String> filePath;
  final Value<DateTime> createdAt;
  const PlacePhotosCompanion({
    this.id = const Value.absent(),
    this.placeClusterId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PlacePhotosCompanion.insert({
    this.id = const Value.absent(),
    required int placeClusterId,
    required String filePath,
    required DateTime createdAt,
  }) : placeClusterId = Value(placeClusterId),
       filePath = Value(filePath),
       createdAt = Value(createdAt);
  static Insertable<PlacePhoto> custom({
    Expression<int>? id,
    Expression<int>? placeClusterId,
    Expression<String>? filePath,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (placeClusterId != null) 'place_cluster_id': placeClusterId,
      if (filePath != null) 'file_path': filePath,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PlacePhotosCompanion copyWith({
    Value<int>? id,
    Value<int>? placeClusterId,
    Value<String>? filePath,
    Value<DateTime>? createdAt,
  }) {
    return PlacePhotosCompanion(
      id: id ?? this.id,
      placeClusterId: placeClusterId ?? this.placeClusterId,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (placeClusterId.present) {
      map['place_cluster_id'] = Variable<int>(placeClusterId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlacePhotosCompanion(')
          ..write('id: $id, ')
          ..write('placeClusterId: $placeClusterId, ')
          ..write('filePath: $filePath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocationPointsTable locationPoints = $LocationPointsTable(this);
  late final $PlaceClustersTable placeClusters = $PlaceClustersTable(this);
  late final $VisitsTable visits = $VisitsTable(this);
  late final $DailySummariesTable dailySummaries = $DailySummariesTable(this);
  late final $InsightsTable insights = $InsightsTable(this);
  late final $PlacePhotosTable placePhotos = $PlacePhotosTable(this);
  late final Index locationPointsTimestamp = Index(
    'location_points_timestamp',
    'CREATE INDEX location_points_timestamp ON location_points (timestamp)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    locationPoints,
    placeClusters,
    visits,
    dailySummaries,
    insights,
    placePhotos,
    locationPointsTimestamp,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'place_clusters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('visits', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'place_clusters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('daily_summaries', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'place_clusters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('place_photos', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$LocationPointsTableCreateCompanionBuilder =
    LocationPointsCompanion Function({
      Value<int> id,
      required DateTime timestamp,
      required double latitude,
      required double longitude,
      required double accuracy,
      Value<double?> speed,
      Value<bool> isMock,
      Value<String> source,
    });
typedef $$LocationPointsTableUpdateCompanionBuilder =
    LocationPointsCompanion Function({
      Value<int> id,
      Value<DateTime> timestamp,
      Value<double> latitude,
      Value<double> longitude,
      Value<double> accuracy,
      Value<double?> speed,
      Value<bool> isMock,
      Value<String> source,
    });

class $$LocationPointsTableFilterComposer
    extends Composer<_$AppDatabase, $LocationPointsTable> {
  $$LocationPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMock => $composableBuilder(
    column: $table.isMock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocationPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocationPointsTable> {
  $$LocationPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMock => $composableBuilder(
    column: $table.isMock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocationPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocationPointsTable> {
  $$LocationPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<bool> get isMock =>
      $composableBuilder(column: $table.isMock, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$LocationPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocationPointsTable,
          LocationPoint,
          $$LocationPointsTableFilterComposer,
          $$LocationPointsTableOrderingComposer,
          $$LocationPointsTableAnnotationComposer,
          $$LocationPointsTableCreateCompanionBuilder,
          $$LocationPointsTableUpdateCompanionBuilder,
          (
            LocationPoint,
            BaseReferences<_$AppDatabase, $LocationPointsTable, LocationPoint>,
          ),
          LocationPoint,
          PrefetchHooks Function()
        > {
  $$LocationPointsTableTableManager(
    _$AppDatabase db,
    $LocationPointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double> accuracy = const Value.absent(),
                Value<double?> speed = const Value.absent(),
                Value<bool> isMock = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => LocationPointsCompanion(
                id: id,
                timestamp: timestamp,
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy,
                speed: speed,
                isMock: isMock,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime timestamp,
                required double latitude,
                required double longitude,
                required double accuracy,
                Value<double?> speed = const Value.absent(),
                Value<bool> isMock = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => LocationPointsCompanion.insert(
                id: id,
                timestamp: timestamp,
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy,
                speed: speed,
                isMock: isMock,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocationPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocationPointsTable,
      LocationPoint,
      $$LocationPointsTableFilterComposer,
      $$LocationPointsTableOrderingComposer,
      $$LocationPointsTableAnnotationComposer,
      $$LocationPointsTableCreateCompanionBuilder,
      $$LocationPointsTableUpdateCompanionBuilder,
      (
        LocationPoint,
        BaseReferences<_$AppDatabase, $LocationPointsTable, LocationPoint>,
      ),
      LocationPoint,
      PrefetchHooks Function()
    >;
typedef $$PlaceClustersTableCreateCompanionBuilder =
    PlaceClustersCompanion Function({
      Value<int> id,
      required double centerLatitude,
      required double centerLongitude,
      required double radiusMeters,
      Value<String?> displayName,
      Value<String?> addressName,
      Value<String?> roadAddressName,
      Value<String?> regionName,
      Value<DateTime?> addressResolvedAt,
      Value<String?> photoPath,
      required DateTime createdAt,
      required DateTime updatedAt,
      required int visitCount,
    });
typedef $$PlaceClustersTableUpdateCompanionBuilder =
    PlaceClustersCompanion Function({
      Value<int> id,
      Value<double> centerLatitude,
      Value<double> centerLongitude,
      Value<double> radiusMeters,
      Value<String?> displayName,
      Value<String?> addressName,
      Value<String?> roadAddressName,
      Value<String?> regionName,
      Value<DateTime?> addressResolvedAt,
      Value<String?> photoPath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> visitCount,
    });

final class $$PlaceClustersTableReferences
    extends BaseReferences<_$AppDatabase, $PlaceClustersTable, PlaceCluster> {
  $$PlaceClustersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$VisitsTable, List<Visit>> _visitsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.visits,
    aliasName: $_aliasNameGenerator(
      db.placeClusters.id,
      db.visits.placeClusterId,
    ),
  );

  $$VisitsTableProcessedTableManager get visitsRefs {
    final manager = $$VisitsTableTableManager(
      $_db,
      $_db.visits,
    ).filter((f) => f.placeClusterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_visitsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DailySummariesTable, List<DailySummary>>
  _dailySummariesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dailySummaries,
    aliasName: $_aliasNameGenerator(
      db.placeClusters.id,
      db.dailySummaries.longestStayPlaceId,
    ),
  );

  $$DailySummariesTableProcessedTableManager get dailySummariesRefs {
    final manager = $$DailySummariesTableTableManager($_db, $_db.dailySummaries)
        .filter(
          (f) => f.longestStayPlaceId.id.sqlEquals($_itemColumn<int>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_dailySummariesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlacePhotosTable, List<PlacePhoto>>
  _placePhotosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.placePhotos,
    aliasName: $_aliasNameGenerator(
      db.placeClusters.id,
      db.placePhotos.placeClusterId,
    ),
  );

  $$PlacePhotosTableProcessedTableManager get placePhotosRefs {
    final manager = $$PlacePhotosTableTableManager(
      $_db,
      $_db.placePhotos,
    ).filter((f) => f.placeClusterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_placePhotosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaceClustersTableFilterComposer
    extends Composer<_$AppDatabase, $PlaceClustersTable> {
  $$PlaceClustersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get centerLatitude => $composableBuilder(
    column: $table.centerLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get centerLongitude => $composableBuilder(
    column: $table.centerLongitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get radiusMeters => $composableBuilder(
    column: $table.radiusMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addressName => $composableBuilder(
    column: $table.addressName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roadAddressName => $composableBuilder(
    column: $table.roadAddressName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regionName => $composableBuilder(
    column: $table.regionName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addressResolvedAt => $composableBuilder(
    column: $table.addressResolvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> visitsRefs(
    Expression<bool> Function($$VisitsTableFilterComposer f) f,
  ) {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.placeClusterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableFilterComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> dailySummariesRefs(
    Expression<bool> Function($$DailySummariesTableFilterComposer f) f,
  ) {
    final $$DailySummariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dailySummaries,
      getReferencedColumn: (t) => t.longestStayPlaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailySummariesTableFilterComposer(
            $db: $db,
            $table: $db.dailySummaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> placePhotosRefs(
    Expression<bool> Function($$PlacePhotosTableFilterComposer f) f,
  ) {
    final $$PlacePhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.placePhotos,
      getReferencedColumn: (t) => t.placeClusterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacePhotosTableFilterComposer(
            $db: $db,
            $table: $db.placePhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaceClustersTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaceClustersTable> {
  $$PlaceClustersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get centerLatitude => $composableBuilder(
    column: $table.centerLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get centerLongitude => $composableBuilder(
    column: $table.centerLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get radiusMeters => $composableBuilder(
    column: $table.radiusMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addressName => $composableBuilder(
    column: $table.addressName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roadAddressName => $composableBuilder(
    column: $table.roadAddressName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regionName => $composableBuilder(
    column: $table.regionName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addressResolvedAt => $composableBuilder(
    column: $table.addressResolvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaceClustersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaceClustersTable> {
  $$PlaceClustersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get centerLatitude => $composableBuilder(
    column: $table.centerLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get centerLongitude => $composableBuilder(
    column: $table.centerLongitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get radiusMeters => $composableBuilder(
    column: $table.radiusMeters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get addressName => $composableBuilder(
    column: $table.addressName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roadAddressName => $composableBuilder(
    column: $table.roadAddressName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get regionName => $composableBuilder(
    column: $table.regionName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addressResolvedAt => $composableBuilder(
    column: $table.addressResolvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => column,
  );

  Expression<T> visitsRefs<T extends Object>(
    Expression<T> Function($$VisitsTableAnnotationComposer a) f,
  ) {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.placeClusterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> dailySummariesRefs<T extends Object>(
    Expression<T> Function($$DailySummariesTableAnnotationComposer a) f,
  ) {
    final $$DailySummariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dailySummaries,
      getReferencedColumn: (t) => t.longestStayPlaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailySummariesTableAnnotationComposer(
            $db: $db,
            $table: $db.dailySummaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> placePhotosRefs<T extends Object>(
    Expression<T> Function($$PlacePhotosTableAnnotationComposer a) f,
  ) {
    final $$PlacePhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.placePhotos,
      getReferencedColumn: (t) => t.placeClusterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlacePhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.placePhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaceClustersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaceClustersTable,
          PlaceCluster,
          $$PlaceClustersTableFilterComposer,
          $$PlaceClustersTableOrderingComposer,
          $$PlaceClustersTableAnnotationComposer,
          $$PlaceClustersTableCreateCompanionBuilder,
          $$PlaceClustersTableUpdateCompanionBuilder,
          (PlaceCluster, $$PlaceClustersTableReferences),
          PlaceCluster,
          PrefetchHooks Function({
            bool visitsRefs,
            bool dailySummariesRefs,
            bool placePhotosRefs,
          })
        > {
  $$PlaceClustersTableTableManager(_$AppDatabase db, $PlaceClustersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaceClustersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaceClustersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaceClustersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> centerLatitude = const Value.absent(),
                Value<double> centerLongitude = const Value.absent(),
                Value<double> radiusMeters = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> addressName = const Value.absent(),
                Value<String?> roadAddressName = const Value.absent(),
                Value<String?> regionName = const Value.absent(),
                Value<DateTime?> addressResolvedAt = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> visitCount = const Value.absent(),
              }) => PlaceClustersCompanion(
                id: id,
                centerLatitude: centerLatitude,
                centerLongitude: centerLongitude,
                radiusMeters: radiusMeters,
                displayName: displayName,
                addressName: addressName,
                roadAddressName: roadAddressName,
                regionName: regionName,
                addressResolvedAt: addressResolvedAt,
                photoPath: photoPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                visitCount: visitCount,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double centerLatitude,
                required double centerLongitude,
                required double radiusMeters,
                Value<String?> displayName = const Value.absent(),
                Value<String?> addressName = const Value.absent(),
                Value<String?> roadAddressName = const Value.absent(),
                Value<String?> regionName = const Value.absent(),
                Value<DateTime?> addressResolvedAt = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                required int visitCount,
              }) => PlaceClustersCompanion.insert(
                id: id,
                centerLatitude: centerLatitude,
                centerLongitude: centerLongitude,
                radiusMeters: radiusMeters,
                displayName: displayName,
                addressName: addressName,
                roadAddressName: roadAddressName,
                regionName: regionName,
                addressResolvedAt: addressResolvedAt,
                photoPath: photoPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                visitCount: visitCount,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaceClustersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                visitsRefs = false,
                dailySummariesRefs = false,
                placePhotosRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (visitsRefs) db.visits,
                    if (dailySummariesRefs) db.dailySummaries,
                    if (placePhotosRefs) db.placePhotos,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (visitsRefs)
                        await $_getPrefetchedData<
                          PlaceCluster,
                          $PlaceClustersTable,
                          Visit
                        >(
                          currentTable: table,
                          referencedTable: $$PlaceClustersTableReferences
                              ._visitsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaceClustersTableReferences(
                                db,
                                table,
                                p0,
                              ).visitsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.placeClusterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (dailySummariesRefs)
                        await $_getPrefetchedData<
                          PlaceCluster,
                          $PlaceClustersTable,
                          DailySummary
                        >(
                          currentTable: table,
                          referencedTable: $$PlaceClustersTableReferences
                              ._dailySummariesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaceClustersTableReferences(
                                db,
                                table,
                                p0,
                              ).dailySummariesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.longestStayPlaceId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (placePhotosRefs)
                        await $_getPrefetchedData<
                          PlaceCluster,
                          $PlaceClustersTable,
                          PlacePhoto
                        >(
                          currentTable: table,
                          referencedTable: $$PlaceClustersTableReferences
                              ._placePhotosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaceClustersTableReferences(
                                db,
                                table,
                                p0,
                              ).placePhotosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.placeClusterId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlaceClustersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaceClustersTable,
      PlaceCluster,
      $$PlaceClustersTableFilterComposer,
      $$PlaceClustersTableOrderingComposer,
      $$PlaceClustersTableAnnotationComposer,
      $$PlaceClustersTableCreateCompanionBuilder,
      $$PlaceClustersTableUpdateCompanionBuilder,
      (PlaceCluster, $$PlaceClustersTableReferences),
      PlaceCluster,
      PrefetchHooks Function({
        bool visitsRefs,
        bool dailySummariesRefs,
        bool placePhotosRefs,
      })
    >;
typedef $$VisitsTableCreateCompanionBuilder =
    VisitsCompanion Function({
      Value<int> id,
      Value<int?> placeClusterId,
      required DateTime startedAt,
      required DateTime endedAt,
      required int durationMinutes,
      required double representativeLatitude,
      required double representativeLongitude,
    });
typedef $$VisitsTableUpdateCompanionBuilder =
    VisitsCompanion Function({
      Value<int> id,
      Value<int?> placeClusterId,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
      Value<int> durationMinutes,
      Value<double> representativeLatitude,
      Value<double> representativeLongitude,
    });

final class $$VisitsTableReferences
    extends BaseReferences<_$AppDatabase, $VisitsTable, Visit> {
  $$VisitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaceClustersTable _placeClusterIdTable(_$AppDatabase db) =>
      db.placeClusters.createAlias(
        $_aliasNameGenerator(db.visits.placeClusterId, db.placeClusters.id),
      );

  $$PlaceClustersTableProcessedTableManager? get placeClusterId {
    final $_column = $_itemColumn<int>('place_cluster_id');
    if ($_column == null) return null;
    final manager = $$PlaceClustersTableTableManager(
      $_db,
      $_db.placeClusters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_placeClusterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VisitsTableFilterComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get representativeLatitude => $composableBuilder(
    column: $table.representativeLatitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get representativeLongitude => $composableBuilder(
    column: $table.representativeLongitude,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaceClustersTableFilterComposer get placeClusterId {
    final $$PlaceClustersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placeClusterId,
      referencedTable: $db.placeClusters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaceClustersTableFilterComposer(
            $db: $db,
            $table: $db.placeClusters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitsTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get representativeLatitude => $composableBuilder(
    column: $table.representativeLatitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get representativeLongitude => $composableBuilder(
    column: $table.representativeLongitude,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaceClustersTableOrderingComposer get placeClusterId {
    final $$PlaceClustersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placeClusterId,
      referencedTable: $db.placeClusters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaceClustersTableOrderingComposer(
            $db: $db,
            $table: $db.placeClusters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<double> get representativeLatitude => $composableBuilder(
    column: $table.representativeLatitude,
    builder: (column) => column,
  );

  GeneratedColumn<double> get representativeLongitude => $composableBuilder(
    column: $table.representativeLongitude,
    builder: (column) => column,
  );

  $$PlaceClustersTableAnnotationComposer get placeClusterId {
    final $$PlaceClustersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placeClusterId,
      referencedTable: $db.placeClusters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaceClustersTableAnnotationComposer(
            $db: $db,
            $table: $db.placeClusters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitsTable,
          Visit,
          $$VisitsTableFilterComposer,
          $$VisitsTableOrderingComposer,
          $$VisitsTableAnnotationComposer,
          $$VisitsTableCreateCompanionBuilder,
          $$VisitsTableUpdateCompanionBuilder,
          (Visit, $$VisitsTableReferences),
          Visit,
          PrefetchHooks Function({bool placeClusterId})
        > {
  $$VisitsTableTableManager(_$AppDatabase db, $VisitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> placeClusterId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<double> representativeLatitude = const Value.absent(),
                Value<double> representativeLongitude = const Value.absent(),
              }) => VisitsCompanion(
                id: id,
                placeClusterId: placeClusterId,
                startedAt: startedAt,
                endedAt: endedAt,
                durationMinutes: durationMinutes,
                representativeLatitude: representativeLatitude,
                representativeLongitude: representativeLongitude,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> placeClusterId = const Value.absent(),
                required DateTime startedAt,
                required DateTime endedAt,
                required int durationMinutes,
                required double representativeLatitude,
                required double representativeLongitude,
              }) => VisitsCompanion.insert(
                id: id,
                placeClusterId: placeClusterId,
                startedAt: startedAt,
                endedAt: endedAt,
                durationMinutes: durationMinutes,
                representativeLatitude: representativeLatitude,
                representativeLongitude: representativeLongitude,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$VisitsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({placeClusterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (placeClusterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.placeClusterId,
                                referencedTable: $$VisitsTableReferences
                                    ._placeClusterIdTable(db),
                                referencedColumn: $$VisitsTableReferences
                                    ._placeClusterIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VisitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitsTable,
      Visit,
      $$VisitsTableFilterComposer,
      $$VisitsTableOrderingComposer,
      $$VisitsTableAnnotationComposer,
      $$VisitsTableCreateCompanionBuilder,
      $$VisitsTableUpdateCompanionBuilder,
      (Visit, $$VisitsTableReferences),
      Visit,
      PrefetchHooks Function({bool placeClusterId})
    >;
typedef $$DailySummariesTableCreateCompanionBuilder =
    DailySummariesCompanion Function({
      required String date,
      required double totalDistanceMeters,
      required int movingMinutes,
      required int stationaryMinutes,
      required int visitCount,
      required int newPlaceCount,
      Value<int?> longestStayPlaceId,
      Value<int> rowid,
    });
typedef $$DailySummariesTableUpdateCompanionBuilder =
    DailySummariesCompanion Function({
      Value<String> date,
      Value<double> totalDistanceMeters,
      Value<int> movingMinutes,
      Value<int> stationaryMinutes,
      Value<int> visitCount,
      Value<int> newPlaceCount,
      Value<int?> longestStayPlaceId,
      Value<int> rowid,
    });

final class $$DailySummariesTableReferences
    extends BaseReferences<_$AppDatabase, $DailySummariesTable, DailySummary> {
  $$DailySummariesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaceClustersTable _longestStayPlaceIdTable(_$AppDatabase db) =>
      db.placeClusters.createAlias(
        $_aliasNameGenerator(
          db.dailySummaries.longestStayPlaceId,
          db.placeClusters.id,
        ),
      );

  $$PlaceClustersTableProcessedTableManager? get longestStayPlaceId {
    final $_column = $_itemColumn<int>('longest_stay_place_id');
    if ($_column == null) return null;
    final manager = $$PlaceClustersTableTableManager(
      $_db,
      $_db.placeClusters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_longestStayPlaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DailySummariesTableFilterComposer
    extends Composer<_$AppDatabase, $DailySummariesTable> {
  $$DailySummariesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDistanceMeters => $composableBuilder(
    column: $table.totalDistanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get movingMinutes => $composableBuilder(
    column: $table.movingMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stationaryMinutes => $composableBuilder(
    column: $table.stationaryMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newPlaceCount => $composableBuilder(
    column: $table.newPlaceCount,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaceClustersTableFilterComposer get longestStayPlaceId {
    final $$PlaceClustersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.longestStayPlaceId,
      referencedTable: $db.placeClusters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaceClustersTableFilterComposer(
            $db: $db,
            $table: $db.placeClusters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailySummariesTableOrderingComposer
    extends Composer<_$AppDatabase, $DailySummariesTable> {
  $$DailySummariesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDistanceMeters => $composableBuilder(
    column: $table.totalDistanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movingMinutes => $composableBuilder(
    column: $table.movingMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stationaryMinutes => $composableBuilder(
    column: $table.stationaryMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newPlaceCount => $composableBuilder(
    column: $table.newPlaceCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaceClustersTableOrderingComposer get longestStayPlaceId {
    final $$PlaceClustersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.longestStayPlaceId,
      referencedTable: $db.placeClusters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaceClustersTableOrderingComposer(
            $db: $db,
            $table: $db.placeClusters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailySummariesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailySummariesTable> {
  $$DailySummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get totalDistanceMeters => $composableBuilder(
    column: $table.totalDistanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get movingMinutes => $composableBuilder(
    column: $table.movingMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stationaryMinutes => $composableBuilder(
    column: $table.stationaryMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get newPlaceCount => $composableBuilder(
    column: $table.newPlaceCount,
    builder: (column) => column,
  );

  $$PlaceClustersTableAnnotationComposer get longestStayPlaceId {
    final $$PlaceClustersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.longestStayPlaceId,
      referencedTable: $db.placeClusters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaceClustersTableAnnotationComposer(
            $db: $db,
            $table: $db.placeClusters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailySummariesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailySummariesTable,
          DailySummary,
          $$DailySummariesTableFilterComposer,
          $$DailySummariesTableOrderingComposer,
          $$DailySummariesTableAnnotationComposer,
          $$DailySummariesTableCreateCompanionBuilder,
          $$DailySummariesTableUpdateCompanionBuilder,
          (DailySummary, $$DailySummariesTableReferences),
          DailySummary,
          PrefetchHooks Function({bool longestStayPlaceId})
        > {
  $$DailySummariesTableTableManager(
    _$AppDatabase db,
    $DailySummariesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailySummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailySummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailySummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<double> totalDistanceMeters = const Value.absent(),
                Value<int> movingMinutes = const Value.absent(),
                Value<int> stationaryMinutes = const Value.absent(),
                Value<int> visitCount = const Value.absent(),
                Value<int> newPlaceCount = const Value.absent(),
                Value<int?> longestStayPlaceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailySummariesCompanion(
                date: date,
                totalDistanceMeters: totalDistanceMeters,
                movingMinutes: movingMinutes,
                stationaryMinutes: stationaryMinutes,
                visitCount: visitCount,
                newPlaceCount: newPlaceCount,
                longestStayPlaceId: longestStayPlaceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required double totalDistanceMeters,
                required int movingMinutes,
                required int stationaryMinutes,
                required int visitCount,
                required int newPlaceCount,
                Value<int?> longestStayPlaceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailySummariesCompanion.insert(
                date: date,
                totalDistanceMeters: totalDistanceMeters,
                movingMinutes: movingMinutes,
                stationaryMinutes: stationaryMinutes,
                visitCount: visitCount,
                newPlaceCount: newPlaceCount,
                longestStayPlaceId: longestStayPlaceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DailySummariesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({longestStayPlaceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (longestStayPlaceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.longestStayPlaceId,
                                referencedTable: $$DailySummariesTableReferences
                                    ._longestStayPlaceIdTable(db),
                                referencedColumn:
                                    $$DailySummariesTableReferences
                                        ._longestStayPlaceIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DailySummariesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailySummariesTable,
      DailySummary,
      $$DailySummariesTableFilterComposer,
      $$DailySummariesTableOrderingComposer,
      $$DailySummariesTableAnnotationComposer,
      $$DailySummariesTableCreateCompanionBuilder,
      $$DailySummariesTableUpdateCompanionBuilder,
      (DailySummary, $$DailySummariesTableReferences),
      DailySummary,
      PrefetchHooks Function({bool longestStayPlaceId})
    >;
typedef $$InsightsTableCreateCompanionBuilder =
    InsightsCompanion Function({
      Value<int> id,
      required DateTime date,
      required String type,
      required String severity,
      required String title,
      required String body,
      required String evidence,
      required DateTime createdAt,
    });
typedef $$InsightsTableUpdateCompanionBuilder =
    InsightsCompanion Function({
      Value<int> id,
      Value<DateTime> date,
      Value<String> type,
      Value<String> severity,
      Value<String> title,
      Value<String> body,
      Value<String> evidence,
      Value<DateTime> createdAt,
    });

class $$InsightsTableFilterComposer
    extends Composer<_$AppDatabase, $InsightsTable> {
  $$InsightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evidence => $composableBuilder(
    column: $table.evidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InsightsTableOrderingComposer
    extends Composer<_$AppDatabase, $InsightsTable> {
  $$InsightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evidence => $composableBuilder(
    column: $table.evidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InsightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InsightsTable> {
  $$InsightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get evidence =>
      $composableBuilder(column: $table.evidence, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$InsightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InsightsTable,
          Insight,
          $$InsightsTableFilterComposer,
          $$InsightsTableOrderingComposer,
          $$InsightsTableAnnotationComposer,
          $$InsightsTableCreateCompanionBuilder,
          $$InsightsTableUpdateCompanionBuilder,
          (Insight, BaseReferences<_$AppDatabase, $InsightsTable, Insight>),
          Insight,
          PrefetchHooks Function()
        > {
  $$InsightsTableTableManager(_$AppDatabase db, $InsightsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InsightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InsightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InsightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> evidence = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => InsightsCompanion(
                id: id,
                date: date,
                type: type,
                severity: severity,
                title: title,
                body: body,
                evidence: evidence,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime date,
                required String type,
                required String severity,
                required String title,
                required String body,
                required String evidence,
                required DateTime createdAt,
              }) => InsightsCompanion.insert(
                id: id,
                date: date,
                type: type,
                severity: severity,
                title: title,
                body: body,
                evidence: evidence,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InsightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InsightsTable,
      Insight,
      $$InsightsTableFilterComposer,
      $$InsightsTableOrderingComposer,
      $$InsightsTableAnnotationComposer,
      $$InsightsTableCreateCompanionBuilder,
      $$InsightsTableUpdateCompanionBuilder,
      (Insight, BaseReferences<_$AppDatabase, $InsightsTable, Insight>),
      Insight,
      PrefetchHooks Function()
    >;
typedef $$PlacePhotosTableCreateCompanionBuilder =
    PlacePhotosCompanion Function({
      Value<int> id,
      required int placeClusterId,
      required String filePath,
      required DateTime createdAt,
    });
typedef $$PlacePhotosTableUpdateCompanionBuilder =
    PlacePhotosCompanion Function({
      Value<int> id,
      Value<int> placeClusterId,
      Value<String> filePath,
      Value<DateTime> createdAt,
    });

final class $$PlacePhotosTableReferences
    extends BaseReferences<_$AppDatabase, $PlacePhotosTable, PlacePhoto> {
  $$PlacePhotosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaceClustersTable _placeClusterIdTable(_$AppDatabase db) =>
      db.placeClusters.createAlias(
        $_aliasNameGenerator(
          db.placePhotos.placeClusterId,
          db.placeClusters.id,
        ),
      );

  $$PlaceClustersTableProcessedTableManager get placeClusterId {
    final $_column = $_itemColumn<int>('place_cluster_id')!;

    final manager = $$PlaceClustersTableTableManager(
      $_db,
      $_db.placeClusters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_placeClusterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlacePhotosTableFilterComposer
    extends Composer<_$AppDatabase, $PlacePhotosTable> {
  $$PlacePhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PlaceClustersTableFilterComposer get placeClusterId {
    final $$PlaceClustersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placeClusterId,
      referencedTable: $db.placeClusters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaceClustersTableFilterComposer(
            $db: $db,
            $table: $db.placeClusters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlacePhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $PlacePhotosTable> {
  $$PlacePhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaceClustersTableOrderingComposer get placeClusterId {
    final $$PlaceClustersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placeClusterId,
      referencedTable: $db.placeClusters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaceClustersTableOrderingComposer(
            $db: $db,
            $table: $db.placeClusters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlacePhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlacePhotosTable> {
  $$PlacePhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PlaceClustersTableAnnotationComposer get placeClusterId {
    final $$PlaceClustersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.placeClusterId,
      referencedTable: $db.placeClusters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaceClustersTableAnnotationComposer(
            $db: $db,
            $table: $db.placeClusters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlacePhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlacePhotosTable,
          PlacePhoto,
          $$PlacePhotosTableFilterComposer,
          $$PlacePhotosTableOrderingComposer,
          $$PlacePhotosTableAnnotationComposer,
          $$PlacePhotosTableCreateCompanionBuilder,
          $$PlacePhotosTableUpdateCompanionBuilder,
          (PlacePhoto, $$PlacePhotosTableReferences),
          PlacePhoto,
          PrefetchHooks Function({bool placeClusterId})
        > {
  $$PlacePhotosTableTableManager(_$AppDatabase db, $PlacePhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlacePhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlacePhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlacePhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> placeClusterId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PlacePhotosCompanion(
                id: id,
                placeClusterId: placeClusterId,
                filePath: filePath,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int placeClusterId,
                required String filePath,
                required DateTime createdAt,
              }) => PlacePhotosCompanion.insert(
                id: id,
                placeClusterId: placeClusterId,
                filePath: filePath,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlacePhotosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({placeClusterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (placeClusterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.placeClusterId,
                                referencedTable: $$PlacePhotosTableReferences
                                    ._placeClusterIdTable(db),
                                referencedColumn: $$PlacePhotosTableReferences
                                    ._placeClusterIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlacePhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlacePhotosTable,
      PlacePhoto,
      $$PlacePhotosTableFilterComposer,
      $$PlacePhotosTableOrderingComposer,
      $$PlacePhotosTableAnnotationComposer,
      $$PlacePhotosTableCreateCompanionBuilder,
      $$PlacePhotosTableUpdateCompanionBuilder,
      (PlacePhoto, $$PlacePhotosTableReferences),
      PlacePhoto,
      PrefetchHooks Function({bool placeClusterId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocationPointsTableTableManager get locationPoints =>
      $$LocationPointsTableTableManager(_db, _db.locationPoints);
  $$PlaceClustersTableTableManager get placeClusters =>
      $$PlaceClustersTableTableManager(_db, _db.placeClusters);
  $$VisitsTableTableManager get visits =>
      $$VisitsTableTableManager(_db, _db.visits);
  $$DailySummariesTableTableManager get dailySummaries =>
      $$DailySummariesTableTableManager(_db, _db.dailySummaries);
  $$InsightsTableTableManager get insights =>
      $$InsightsTableTableManager(_db, _db.insights);
  $$PlacePhotosTableTableManager get placePhotos =>
      $$PlacePhotosTableTableManager(_db, _db.placePhotos);
}
