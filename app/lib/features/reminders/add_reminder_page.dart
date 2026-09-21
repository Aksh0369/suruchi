import 'package:flutter/material.dart';

import '../../domain/entities/reminder_category.dart';
import 'reminder_form.dart';

/// Full-page version of the Add Reminder flow, reached from each category
/// card's own quick-add button on Home. Same form as the bottom sheet used
/// elsewhere (editing, category list's FAB) — just presented as a page.
class AddReminderPage extends StatelessWidget {
  const AddReminderPage({super.key, required this.category});

  final ReminderCategory category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New ${category.label} reminder')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ReminderForm(category: category),
        ),
      ),
    );
  }
}
