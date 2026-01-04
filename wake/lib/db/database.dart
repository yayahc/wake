import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class Alarm extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get ringAt => dateTime()();
  TextColumn get message => text().withLength(min: 6, max: 64)();
  DateTimeColumn get createdAt => dateTime().nullable()();
}

@DriftDatabase(tables: [Alarm])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static AppDatabase get instance => AppDatabase();

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'wdb',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
