import 'package:flutter/material.dart';

import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_category.dart';
import 'reminder_form.dart';

Future<void> showAddEditReminderSheet(
  BuildContext context, {
  required ReminderCategory category,
  Reminder? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddEditReminderSheet(category: category, existing: existing),
  );
}

class _AddEditReminderSheet extends StatelessWidget {
  const _AddEditReminderSheet({required this.category, this.existing});

  final ReminderCategory category;
  final Reminder? existing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ReminderForm(category: category, existing: existing),
            ],
          ),
        ),
      ),
    );
  }
}
