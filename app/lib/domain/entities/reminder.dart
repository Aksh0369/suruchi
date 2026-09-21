import 'reminder_category.dart';

enum ReminderType { normal, alarm }

enum ReminderPriority { low, normal, high }

/// How a task's reminder timing works — chosen once per task:
///
/// - [deadline]: a specific date+time to finish by. Reminders fire at
///   -1hr, -30min, at the time, and +30min after (fixed, not configurable).
/// - [recurring]: no specific deadline, just "I have to do this regularly".
///   [timesPerWeek] reminders a week, at [preferredTimeMinutes] time of
///   day; which days is decided automatically (not by the user).
/// - [random]: exactly one nudge a week, on a random day and random time
///   of day, repeating every week until the task is marked done.
enum ScheduleMode { deadline, recurring, random }

/// Plain domain model — the UI and business logic work with this, never
/// with a Drift row directly, so the storage layer can change without
/// touching anything above the repository.
class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.type = ReminderType.normal,
    this.scheduleMode = ScheduleMode.deadline,
    this.scheduledAt,
    this.timesPerWeek,
    this.preferredTimeMinutes,
    this.priority = ReminderPriority.normal,
    this.soundId,
    this.vibrationEnabled = true,
    this.snoozeMinutes = 5,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final ReminderCategory category;
  final ReminderType type;

  final ScheduleMode scheduleMode;
  /// The deadline, when [scheduleMode] is [ScheduleMode.deadline]. Null
  /// otherwise — recurring/random tasks have no single fixed instant.
  final DateTime? scheduledAt;
  /// How many times a week, when [scheduleMode] is [ScheduleMode.recurring].
  final int? timesPerWeek;
  /// Minutes since midnight, the recurring task's time of day.
  final int? preferredTimeMinutes;

  final ReminderPriority priority;
  final String? soundId;
  final bool vibrationEnabled;
  final int snoozeMinutes;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reminder copyWith({
    String? title,
    Object? description = _unset,
    ReminderCategory? category,
    ReminderType? type,
    ScheduleMode? scheduleMode,
    Object? scheduledAt = _unset,
    Object? timesPerWeek = _unset,
    Object? preferredTimeMinutes = _unset,
    ReminderPriority? priority,
    Object? soundId = _unset,
    bool? vibrationEnabled,
    int? snoozeMinutes,
    bool? isCompleted,
    Object? completedAt = _unset,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      description: description == _unset ? this.description : description as String?,
      category: category ?? this.category,
      type: type ?? this.type,
      scheduleMode: scheduleMode ?? this.scheduleMode,
      scheduledAt: scheduledAt == _unset ? this.scheduledAt : scheduledAt as DateTime?,
      timesPerWeek: timesPerWeek == _unset ? this.timesPerWeek : timesPerWeek as int?,
      preferredTimeMinutes: preferredTimeMinutes == _unset
          ? this.preferredTimeMinutes
          : preferredTimeMinutes as int?,
      priority: priority ?? this.priority,
      soundId: soundId == _unset ? this.soundId : soundId as String?,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt == _unset ? this.completedAt : completedAt as DateTime?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

const _unset = Object();
