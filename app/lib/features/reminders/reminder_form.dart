import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_category.dart';

/// The reminder create/edit form fields — shared by the quick bottom sheet
/// and the full-page Add Reminder screen, so both stay in sync with one
/// implementation. Saving pops the current route either way.
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
  late DateTime _scheduledAt;
  late RepeatRule _repeatRule;
  late ReminderPriority _priority;
  bool _moreOptionsOpen = false;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _scheduledAt = existing?.scheduledAt ?? _defaultTime();
    _repeatRule = existing?.repeatRule ?? RepeatRule.none;
    _priority = existing?.priority ?? ReminderPriority.normal;
  }

  DateTime _defaultTime() {
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
      scheduledAt: _scheduledAt,
      repeatRule: _repeatRule,
      priority: _priority,
      updatedAt: DateTime.now(),
    );

    await repo.upsert(reminder);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;

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
            hintText: 'What do you want to remember?',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 14),
        Text('When?', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            _PillButton(label: _formatDate(_scheduledAt), onTap: _pickDate),
            const SizedBox(width: 10),
            _PillButton(label: _formatTime(_scheduledAt), onTap: _pickTime),
          ],
        ),
        const SizedBox(height: 14),
        Text('Repeat?', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<RepeatRule>(
          initialValue: _repeatRule,
          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          items: const [
            DropdownMenuItem(value: RepeatRule.none, child: Text('Never')),
            DropdownMenuItem(value: RepeatRule.daily, child: Text('Every day')),
            DropdownMenuItem(value: RepeatRule.weekly, child: Text('Every week')),
          ],
          onChanged: (value) => setState(() => _repeatRule = value ?? RepeatRule.none),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => setState(() => _moreOptionsOpen = !_moreOptionsOpen),
          icon: Icon(_moreOptionsOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded),
          label: Text(_moreOptionsOpen ? 'Fewer options' : 'More options'),
        ),
        if (_moreOptionsOpen) ...[
          TextField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          Text('Priority', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<ReminderPriority>(
            segments: const [
              ButtonSegment(value: ReminderPriority.low, label: Text('Low')),
              ButtonSegment(value: ReminderPriority.normal, label: Text('Normal')),
              ButtonSegment(value: ReminderPriority.high, label: Text('High')),
            ],
            selected: {_priority},
            onSelectionChanged: (s) => setState(() => _priority = s.first),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_isEditing ? 'SAVE CHANGES' : 'CREATE REMINDER'),
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
