import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_category.dart';

/// The task create/edit form fields — shared by every place a task can be
/// added or edited, so there's one implementation instead of several
/// screens drifting apart. Saving pops the current route.
class ReminderForm extends ConsumerStatefulWidget {
  const ReminderForm({super.key, required this.category, this.existing});

  final ReminderCategory category;
  final Reminder? existing;

  @override
  ConsumerState<ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends ConsumerState<ReminderForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late ScheduleMode _scheduleMode;
  late DateTime _scheduledAt;
  late int _timesPerWeek;
  late TimeOfDay _preferredTime;
  late ReminderPriority _priority;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _scheduleMode = existing?.scheduleMode ?? ScheduleMode.deadline;
    _scheduledAt = existing?.scheduledAt ?? _defaultDeadline();
    _timesPerWeek = existing?.timesPerWeek ?? 3;
    _preferredTime = existing?.preferredTimeMinutes != null
        ? TimeOfDay(
            hour: existing!.preferredTimeMinutes! ~/ 60,
            minute: existing.preferredTimeMinutes! % 60,
          )
        : const TimeOfDay(hour: 18, minute: 0);
    _priority = existing?.priority ?? ReminderPriority.normal;
  }

  DateTime _defaultDeadline() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    setState(() {
      _scheduledAt = DateTime(picked.year, picked.month, picked.day, _scheduledAt.hour, _scheduledAt.minute);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (picked == null) return;
    setState(() {
      _scheduledAt = DateTime(
        _scheduledAt.year, _scheduledAt.month, _scheduledAt.day, picked.hour, picked.minute,
      );
    });
  }

  Future<void> _pickPreferredTime() async {
    final picked = await showTimePicker(context: context, initialTime: _preferredTime);
    if (picked == null) return;
    setState(() => _preferredTime = picked);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);

    final repo = ref.read(reminderRepositoryProvider);
    final base = widget.existing ?? repo.buildDraft(widget.category);
    final reminder = base.copyWith(
      title: title,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      scheduleMode: _scheduleMode,
      scheduledAt: _scheduleMode == ScheduleMode.deadline ? _scheduledAt : null,
      timesPerWeek: _scheduleMode == ScheduleMode.recurring ? _timesPerWeek : null,
      preferredTimeMinutes: _scheduleMode == ScheduleMode.recurring
          ? _preferredTime.hour * 60 + _preferredTime.minute
          : null,
      priority: _priority,
      updatedAt: DateTime.now(),
    );

    await repo.upsert(reminder);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(category.icon, color: category.color, size: 22),
            const SizedBox(width: 8),
            Text(category.label.toUpperCase(), style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _titleController,
          autofocus: !_isEditing,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'What do you want to do?',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),
        Text('Remind me how?', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        _ModeToggle(
          selected: _scheduleMode,
          onChanged: (value) => setState(() => _scheduleMode = value),
        ),
        const SizedBox(height: 14),
        switch (_scheduleMode) {
          ScheduleMode.deadline => _DeadlineFields(
              scheduledAt: _scheduledAt,
              onPickDate: _pickDate,
              onPickTime: _pickTime,
            ),
          ScheduleMode.recurring => _RecurringFields(
              timesPerWeek: _timesPerWeek,
              preferredTime: _preferredTime,
              onTimesPerWeekChanged: (v) => setState(() => _timesPerWeek = v),
              onPickPreferredTime: _pickPreferredTime,
            ),
          ScheduleMode.random => Text(
              'We\'ll remind you once a week, on a random day and time, '
              'until this is done.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        },
        const SizedBox(height: 18),
        TextField(
          controller: _descriptionController,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        Text('Priority', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        _PriorityToggle(
          selected: _priority,
          onChanged: (value) => setState(() => _priority = value),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_isEditing ? 'SAVE TASK' : 'CREATE TASK'),
          ),
        ),
      ],
    );
  }
}

class _DeadlineFields extends StatelessWidget {
  const _DeadlineFields({
    required this.scheduledAt,
    required this.onPickDate,
    required this.onPickTime,
  });

  final DateTime scheduledAt;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Finish by', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            _PillButton(label: _formatDate(scheduledAt), onTap: onPickDate),
            const SizedBox(width: 10),
            _PillButton(label: _formatTime(scheduledAt), onTap: onPickTime),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ll remind you 1hr before, 30min before, at the time, and 30min after.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RecurringFields extends StatelessWidget {
  const _RecurringFields({
    required this.timesPerWeek,
    required this.preferredTime,
    required this.onTimesPerWeekChanged,
    required this.onPickPreferredTime,
  });

  final int timesPerWeek;
  final TimeOfDay preferredTime;
  final ValueChanged<int> onTimesPerWeekChanged;
  final VoidCallback onPickPreferredTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How many times a week?', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: timesPerWeek,
          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          items: [
            for (var n = 1; n <= 7; n++)
              DropdownMenuItem(value: n, child: Text(n == 7 ? 'Every day' : '$n time${n > 1 ? 's' : ''} a week')),
          ],
          onChanged: (value) => onTimesPerWeekChanged(value ?? timesPerWeek),
        ),
        const SizedBox(height: 14),
        Text('What time of day?', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        _PillButton(label: preferredTime.format(context), onTap: onPickPreferredTime),
        const SizedBox(height: 8),
        Text(
          'We\'ll pick which days automatically.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onTap, child: Text(label));
  }
}

/// Full-width, equal-width toggle where selection is shown purely by
/// filling the selected segment's background — used for both the schedule
/// mode picker and the priority picker so they read as one visual language.
class _SegmentedToggle<T> extends StatelessWidget {
  const _SegmentedToggle({required this.options, required this.selected, required this.onChanged});

  final List<(T value, String label)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == option.$1 ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    option.$2,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected == option.$1 ? scheme.onPrimary : scheme.onSurface,
                      fontWeight: selected == option.$1 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.selected, required this.onChanged});

  final ScheduleMode selected;
  final ValueChanged<ScheduleMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SegmentedToggle<ScheduleMode>(
      selected: selected,
      onChanged: onChanged,
      options: const [
        (ScheduleMode.deadline, 'Deadline'),
        (ScheduleMode.recurring, 'Recurring'),
        (ScheduleMode.random, 'Random'),
      ],
    );
  }
}

class _PriorityToggle extends StatelessWidget {
  const _PriorityToggle({required this.selected, required this.onChanged});

  final ReminderPriority selected;
  final ValueChanged<ReminderPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SegmentedToggle<ReminderPriority>(
      selected: selected,
      onChanged: onChanged,
      options: const [
        (ReminderPriority.low, 'Low'),
        (ReminderPriority.normal, 'Normal'),
        (ReminderPriority.high, 'High'),
      ],
    );
  }
}

String _formatDate(DateTime dt) {
  final today = DateTime.now();
  final isToday = dt.year == today.year && dt.month == today.month && dt.day == today.day;
  final tomorrow = today.add(const Duration(days: 1));
  final isTomorrow = dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day;
  if (isToday) return 'Today';
  if (isTomorrow) return 'Tomorrow';
  return '${dt.day}/${dt.month}/${dt.year}';
}

String _formatTime(DateTime dt) {
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}
