import 'reminder_category.dart';

enum ReminderType { normal, alarm }

enum RepeatRule { none, daily, weekly, custom }

enum ReminderPriority { low, normal, high }

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
    required this.scheduledAt,
    this.repeatRule = RepeatRule.none,
    this.repeatDays,
    this.endDate,
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
  final DateTime scheduledAt;
  final RepeatRule repeatRule;
  final List<int>? repeatDays; // ISO weekday numbers, 1=Mon..7=Sun
  final DateTime? endDate;
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
    DateTime? scheduledAt,
    RepeatRule? repeatRule,
    Object? repeatDays = _unset,
    Object? endDate = _unset,
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
      scheduledAt: scheduledAt ?? this.scheduledAt,
      repeatRule: repeatRule ?? this.repeatRule,
      repeatDays: repeatDays == _unset ? this.repeatDays : repeatDays as List<int>?,
      endDate: endDate == _unset ? this.endDate : endDate as DateTime?,
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
