import 'package:drift/drift.dart';

part 'app_database.g.dart';

@TableIndex(name: 'location_points_timestamp', columns: {#timestamp})
class LocationPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracy => real()();
  RealColumn get speed => real().nullable()();
  BoolColumn get isMock => boolean().withDefault(const Constant(false))();
  TextColumn get source => text().withDefault(const Constant('android'))();
}

class PlaceClusters extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get centerLatitude => real()();
  RealColumn get centerLongitude => real()();
  RealColumn get radiusMeters => real()();
  TextColumn get displayName => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get visitCount => integer()();
}

class Visits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get placeClusterId => integer().nullable().references(
    PlaceClusters,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get durationMinutes => integer()();
  RealColumn get representativeLatitude => real()();
  RealColumn get representativeLongitude => real()();
}

class DailySummaries extends Table {
  TextColumn get date => text()();
  RealColumn get totalDistanceMeters => real()();
  IntColumn get movingMinutes => integer()();
  IntColumn get stationaryMinutes => integer()();
  IntColumn get visitCount => integer()();
  IntColumn get newPlaceCount => integer()();
  IntColumn get longestStayPlaceId => integer().nullable().references(
    PlaceClusters,
    #id,
    onDelete: KeyAction.setNull,
  )();

  @override
  Set<Column<Object>> get primaryKey => {date};
}

class Insights extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get type => text()();
  TextColumn get severity => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get evidence => text()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(
  tables: [LocationPoints, PlaceClusters, Visits, DailySummaries, Insights],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;
}
