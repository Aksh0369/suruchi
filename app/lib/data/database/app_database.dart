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

  // How this task's reminder timing works — see ScheduleMode in the domain
  // entity. Only the columns relevant to the chosen mode are populated.
  TextColumn get scheduleMode => text().withDefault(const Constant('deadline'))();
  DateTimeColumn get scheduledAt => dateTime().nullable()(); // deadline mode
  IntColumn get timesPerWeek => integer().nullable()(); // recurring mode
  IntColumn get preferredTimeMinutes => integer().nullable()(); // recurring mode

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

/// Small device-local key/value store — theme mode, language, notification
/// defaults. Deliberately separate from [Reminders]: this never syncs to
/// the cloud backend, it's per-device.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Reminders, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(appSettings);
      }
      if (from < 3) {
        // Pre-release schema change (repeatRule/repeatDays/endDate replaced
        // by scheduleMode/timesPerWeek/preferredTimeMinutes) — no real user
        // data exists yet, so a clean recreate is simpler than a column
        // migration.
        await m.deleteTable(reminders.actualTableName);
        await m.createTable(reminders);
      }
    },
  );

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
