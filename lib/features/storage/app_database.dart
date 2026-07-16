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
  TextColumn get addressName => text().nullable()();
  TextColumn get roadAddressName => text().nullable()();
  TextColumn get regionName => text().nullable()();
  DateTimeColumn get addressResolvedAt => dateTime().nullable()();
  /// v3에서 장소당 사진 1장을 담던 컬럼. v4부터 PlacePhotos 테이블이
  /// 대체하며, 기존 값은 마이그레이션으로 옮겨진다. 읽지 말 것.
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get visitCount => integer()();
}

class PlacePhotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get placeClusterId => integer().references(
    PlaceClusters,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get filePath => text()();
  DateTimeColumn get createdAt => dateTime()();
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
  TextColumn get date => text().customConstraint(
    "NOT NULL CHECK (date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
  )();
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
  tables: [
    LocationPoints,
    PlaceClusters,
    Visits,
    DailySummaries,
    Insights,
    PlacePhotos,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(placeClusters, placeClusters.addressName);
        await migrator.addColumn(placeClusters, placeClusters.roadAddressName);
        await migrator.addColumn(placeClusters, placeClusters.regionName);
        await migrator.addColumn(
          placeClusters,
          placeClusters.addressResolvedAt,
        );
      }
      if (from < 3) {
        await migrator.addColumn(placeClusters, placeClusters.photoPath);
      }
      if (from < 4) {
        await migrator.createTable(placePhotos);
        // v3의 단일 사진(photo_path)을 새 테이블로 이전한다.
        await customStatement(
          'INSERT INTO place_photos (place_cluster_id, file_path, created_at) '
          'SELECT id, photo_path, updated_at FROM place_clusters '
          'WHERE photo_path IS NOT NULL',
        );
      }
    },
  );
}
