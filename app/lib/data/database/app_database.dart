import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Enum values are stored as their .name string — portable, readable in a
/// DB browser, and matches the JSON the sync API will eventually speak.
///
/// @DataClassName avoids a name clash with the domain-layer `Reminder`
/// entity — this generated class is the raw row, never used above the
/// repository.
@DataClassName('ReminderRow')
class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get category => text()(); // business | self | seva
  TextColumn get type => text().withDefault(const Constant('normal'))();
  DateTimeColumn get scheduledAt => dateTime()();
  TextColumn get repeatRule => text().withDefault(const Constant('none'))();
  // Comma-separated ISO weekday numbers (1=Mon..7=Sun), only when repeatRule=weekly
  TextColumn get repeatDays => text().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get priority => text().withDefault(const Constant('normal'))();
  TextColumn get soundId => text().nullable()();
  BoolColumn get vibrationEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get snoozeMinutes => integer().withDefault(const Constant(5))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Reminders])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'suruchi',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
