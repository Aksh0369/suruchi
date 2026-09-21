import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_category.dart';
import '../../shared/widgets/category_card.dart';
import '../reminders/add_edit_reminder_sheet.dart';
import '../reminders/add_reminder_page.dart';
import '../reminders/category_list_screen.dart';
import '../reminders/reminder_providers.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _today {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  void _openCategory(BuildContext context, ReminderCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CategoryListScreen(category: category)),
    );
  }

  void _openAddReminderPage(BuildContext context, ReminderCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddReminderPage(category: category)),
    );
  }

  int _todayCountFor(List<Reminder> all, ReminderCategory category) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    return all
        .where((r) =>
            r.category == category && !r.isCompleted && r.scheduledAt.isBefore(tomorrow))
        .length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final remindersAsync = ref.watch(allRemindersProvider);

    return Scaffold(
      body: SafeArea(
        child: remindersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Something went wrong: $err')),
          data: (all) {
            final pending = all.where((r) => !r.isCompleted).toList()
              ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
            final nextUp = pending.isEmpty ? null : pending.first;
            final upcoming = pending.skip(nextUp == null ? 0 : 1).take(4).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(_greeting, style: Theme.of(context).textTheme.headlineMedium),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Settings',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _today,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: CategoryCard(
                        category: ReminderCategory.business,
                        todayCount: _todayCountFor(all, ReminderCategory.business),
                        onTap: () => _openCategory(context, ReminderCategory.business),
                        onAddTap: () => _openAddReminderPage(context, ReminderCategory.business),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CategoryCard(
                        category: ReminderCategory.self,
                        todayCount: _todayCountFor(all, ReminderCategory.self),
                        onTap: () => _openCategory(context, ReminderCategory.self),
                        onAddTap: () => _openAddReminderPage(context, ReminderCategory.self),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                CategoryCard(
                  category: ReminderCategory.seva,
                  todayCount: _todayCountFor(all, ReminderCategory.seva),
                  onTap: () => _openCategory(context, ReminderCategory.seva),
                  onAddTap: () => _openAddReminderPage(context, ReminderCategory.seva),
                ),
                if (nextUp != null) ...[
                  const SizedBox(height: 28),
                  Text('NEXT UP', style: _sectionLabelStyle(context)),
                  const SizedBox(height: 10),
                  _NextUpCard(reminder: nextUp),
                ],
                if (upcoming.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text('UPCOMING', style: _sectionLabelStyle(context)),
                  const SizedBox(height: 10),
                  for (final r in upcoming) _UpcomingRow(reminder: r),
                ],
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'સેવા એ જીવનને સાર્થક બનાવવાનો સુંદર માર્ગ છે.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAdd(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showQuickAdd(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What kind of reminder?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            for (final category in ReminderCategory.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(category.icon, color: category.color),
                title: Text(category.label),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showAddEditReminderSheet(context, category: category);
                },
              ),
          ],
        ),
      ),
    );
  }

  TextStyle? _sectionLabelStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: 1.1,
    );
  }
}

class _NextUpCard extends ConsumerWidget {
  const _NextUpCard({required this.reminder});

  final Reminder reminder;

  String get _time {
    final hour = reminder.scheduledAt.hour % 12 == 0 ? 12 : reminder.scheduledAt.hour % 12;
    final minute = reminder.scheduledAt.minute.toString().padLeft(2, '0');
    final period = reminder.scheduledAt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final category = reminder.category;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(category.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_time, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    reminder.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                final repo = ref.read(reminderRepositoryProvider);
                repo.upsert(reminder.copyWith(
                  scheduledAt: reminder.scheduledAt.add(Duration(minutes: reminder.snoozeMinutes)),
                  updatedAt: DateTime.now(),
                ));
              },
              child: const Text('SNOOZE'),
            ),
            FilledButton(
              onPressed: () =>
                  ref.read(reminderRepositoryProvider).setCompleted(reminder.id, true),
              child: const Text('DONE'),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.reminder});

  final Reminder reminder;

  String get _time {
    final hour = reminder.scheduledAt.hour % 12 == 0 ? 12 : reminder.scheduledAt.hour % 12;
    final minute = reminder.scheduledAt.minute.toString().padLeft(2, '0');
    final period = reminder.scheduledAt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final category = reminder.category;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: category.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Text(_time, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              reminder.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
