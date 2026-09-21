import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_category.dart';
import 'reminder_providers.dart';
import 'task_form_page.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key, required this.category});

  final ReminderCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersByCategoryProvider(category));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(category.icon, color: category.color, size: 20),
            const SizedBox(width: 8),
            Text(category.label),
          ],
        ),
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Something went wrong: $err')),
        data: (reminders) => _CategoryReminderList(category: category, reminders: reminders),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TaskFormPage(category: category)),
        ),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _CategoryReminderList extends StatelessWidget {
  const _CategoryReminderList({required this.category, required this.reminders});

  final ReminderCategory category;
  final List<Reminder> reminders;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final completed = reminders.where((r) => r.isCompleted).toList();
    // Recurring/random tasks have no single fixed instant, so they can't be
    // placed in Today/Upcoming — they get their own section instead.
    final ongoing = reminders
        .where((r) => !r.isCompleted && r.scheduleMode != ScheduleMode.deadline)
        .toList();
    final todayList = reminders
        .where((r) =>
            !r.isCompleted &&
            r.scheduleMode == ScheduleMode.deadline &&
            r.scheduledAt!.isBefore(tomorrow))
        .toList();
    final upcoming = reminders
        .where((r) =>
            !r.isCompleted &&
            r.scheduleMode == ScheduleMode.deadline &&
            !r.scheduledAt!.isBefore(tomorrow))
        .toList();

    if (reminders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No ${category.label.toLowerCase()} tasks yet.\nTap + to add one.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        if (todayList.isNotEmpty) ..._section(context, 'TODAY', todayList),
        if (upcoming.isNotEmpty) ..._section(context, 'UPCOMING', upcoming),
        if (ongoing.isNotEmpty) ..._section(context, 'ONGOING', ongoing),
        if (completed.isNotEmpty) ..._section(context, 'COMPLETED', completed),
      ],
    );
  }

  List<Widget> _section(BuildContext context, String title, List<Reminder> items) {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1.1,
          ),
        ),
      ),
      ...items.map((r) => _ReminderTile(reminder: r)),
      const SizedBox(height: 12),
    ];
  }
}

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({required this.reminder});

  final Reminder reminder;

  String get _subtitle {
    switch (reminder.scheduleMode) {
      case ScheduleMode.deadline:
        return _formatTime(reminder.scheduledAt!);
      case ScheduleMode.recurring:
        final n = reminder.timesPerWeek ?? 1;
        final mins = reminder.preferredTimeMinutes ?? 0;
        final time = _formatTime(DateTime(2000, 1, 1, mins ~/ 60, mins % 60));
        return '${n == 7 ? 'Every day' : '$n time${n > 1 ? 's' : ''}/week'} · $time';
      case ScheduleMode.random:
        return 'Random · once a week';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskFormPage(category: reminder.category, existing: reminder),
          ),
        ),
        leading: Checkbox(
          value: reminder.isCompleted,
          onChanged: (value) => ref
              .read(reminderRepositoryProvider)
              .setCompleted(reminder.id, value ?? false),
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
            color: reminder.isCompleted ? scheme.onSurfaceVariant : null,
          ),
        ),
        subtitle: Text(_subtitle),
        trailing: reminder.type == ReminderType.alarm
            ? const Icon(Icons.alarm_rounded, size: 20)
            : null,
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}
