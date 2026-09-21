import 'package:flutter/material.dart';

import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_category.dart';
import 'reminder_form.dart';

/// Full-page add/edit task flow — the only way tasks are created or edited
/// anywhere in the app (no bottom sheet).
class TaskFormPage extends StatelessWidget {
  const TaskFormPage({super.key, required this.category, this.existing});

  final ReminderCategory category;
  final Reminder? existing;

  @override
  Widget build(BuildContext context) {
    final title = existing == null ? 'New ${category.label} task' : 'Edit task';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ReminderForm(category: category, existing: existing),
        ),
      ),
    );
  }
}
