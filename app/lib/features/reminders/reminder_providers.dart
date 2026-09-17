import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/providers/database_provider.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_category.dart';

part 'reminder_providers.g.dart';

@riverpod
Stream<List<Reminder>> allReminders(Ref ref) {
  return ref.watch(reminderRepositoryProvider).watchAll();
}

@riverpod
Stream<List<Reminder>> remindersByCategory(Ref ref, ReminderCategory category) {
  return ref.watch(reminderRepositoryProvider).watchByCategory(category);
}
