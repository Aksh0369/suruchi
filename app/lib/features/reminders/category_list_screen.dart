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
    // One combined "To do" list — deadline tasks soonest-first, then
    // recurring/random tasks (which have no single instant to sort by)
    // after — then everything finished, in a separate Completed section.
    final todo = reminders.where((r) => !r.isCompleted).toList()
      ..sort((a, b) {
        final aTime = a.scheduleMode == ScheduleMode.deadline ? a.scheduledAt : null;
        final bTime = b.scheduleMode == ScheduleMode.deadline ? b.scheduledAt : null;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });
    final completed = reminders.where((r) => r.isCompleted).toList();

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
        if (todo.isNotEmpty) ..._section(context, 'To do', todo),
        if (completed.isNotEmpty) ..._section(context, 'Completed', completed),
      ],
    );
  }

  List<Widget> _section(BuildContext context, String title, List<Reminder> items) {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      ...items.map((r) => _ReminderTile(reminder: r)),
      const SizedBox(height: 16),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: reminder.isCompleted ? scheme.onSurfaceVariant : scheme.onSurface,
          ),
        ),
        subtitle: Text(
          _subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
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
