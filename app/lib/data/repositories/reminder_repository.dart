import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_category.dart';
import '../database/app_database.dart';

const _uuid = Uuid();

class ReminderRepository {
  ReminderRepository(this._db);

  final AppDatabase _db;

  Stream<List<Reminder>> watchAll() {
    return (_db.select(_db.reminders)
          ..orderBy([(r) => OrderingTerm.asc(r.scheduledAt)]))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  Stream<List<Reminder>> watchByCategory(ReminderCategory category) {
    return (_db.select(_db.reminders)
          ..where((r) => r.category.equals(category.name))
          ..orderBy([(r) => OrderingTerm.asc(r.scheduledAt)]))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  Future<Reminder?> getById(String id) async {
    final row = await (_db.select(_db.reminders)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  /// A blank reminder for [category] with sensible defaults, ready to be
  /// customized in the Add Task screen and passed to [upsert].
  Reminder buildDraft(ReminderCategory category) {
    final now = DateTime.now();
    return Reminder(
      id: _uuid.v4(),
      title: '',
      category: category,
      scheduleMode: ScheduleMode.deadline,
      scheduledAt: DateTime(now.year, now.month, now.day, now.hour + 1),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> upsert(Reminder reminder) {
    return _db.into(_db.reminders).insertOnConflictUpdate(_toCompanion(reminder));
  }

  Future<void> setCompleted(String id, bool isCompleted) {
    return (_db.update(_db.reminders)..where((r) => r.id.equals(id))).write(
      RemindersCompanion(
        isCompleted: Value(isCompleted),
        completedAt: Value(isCompleted ? DateTime.now() : null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(String id) {
    return (_db.delete(_db.reminders)..where((r) => r.id.equals(id))).go();
  }
}

Reminder _toEntity(ReminderRow row) {
  return Reminder(
    id: row.id,
    title: row.title,
    description: row.description,
    category: ReminderCategory.values.byName(row.category),
    type: ReminderType.values.byName(row.type),
    scheduleMode: ScheduleMode.values.byName(row.scheduleMode),
    scheduledAt: row.scheduledAt,
    timesPerWeek: row.timesPerWeek,
    preferredTimeMinutes: row.preferredTimeMinutes,
    priority: ReminderPriority.values.byName(row.priority),
    soundId: row.soundId,
    vibrationEnabled: row.vibrationEnabled,
    snoozeMinutes: row.snoozeMinutes,
    isCompleted: row.isCompleted,
    completedAt: row.completedAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}

RemindersCompanion _toCompanion(Reminder r) {
  return RemindersCompanion.insert(
    id: r.id,
    title: r.title,
    description: Value(r.description),
    category: r.category.name,
    type: Value(r.type.name),
    scheduleMode: Value(r.scheduleMode.name),
    scheduledAt: Value(r.scheduledAt),
    timesPerWeek: Value(r.timesPerWeek),
    preferredTimeMinutes: Value(r.preferredTimeMinutes),
    priority: Value(r.priority.name),
    soundId: Value(r.soundId),
    vibrationEnabled: Value(r.vibrationEnabled),
    snoozeMinutes: Value(r.snoozeMinutes),
    isCompleted: Value(r.isCompleted),
    completedAt: Value(r.completedAt),
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );
}
