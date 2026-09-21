import 'package:flutter/material.dart';

import '../../domain/entities/reminder_category.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.todayCount,
    required this.onTap,
    required this.onAddTap,
  });

  final ReminderCategory category;
  final int todayCount;
  final VoidCallback onTap;

  /// Small quick-add button in the card's corner — opens the full-page Add
  /// Reminder screen directly for this category, skipping the category list.
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final soft = isDark ? category.softColorDark : category.softColor;

    return Material(
      color: soft,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: category.color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(category.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    category.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    todayCount == 0 ? 'Nothing today' : '$todayCount today',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: category.color,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onAddTap,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
