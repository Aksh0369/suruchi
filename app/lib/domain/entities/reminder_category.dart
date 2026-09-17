import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The three fixed V1 categories. Deliberately not extensible from the UI —
/// adding a fourth is a product decision, not a config option.
enum ReminderCategory {
  business(
    label: 'Business',
    icon: Icons.work_rounded,
    color: AppColors.business,
    softColor: AppColors.businessSoft,
    softColorDark: AppColors.businessSoftDark,
  ),
  self(
    label: 'Self',
    icon: Icons.self_improvement_rounded,
    color: AppColors.self,
    softColor: AppColors.selfSoft,
    softColorDark: AppColors.selfSoftDark,
  ),
  seva(
    label: 'Seva',
    icon: Icons.volunteer_activism_rounded,
    color: AppColors.seva,
    softColor: AppColors.sevaSoft,
    softColorDark: AppColors.sevaSoftDark,
  );

  const ReminderCategory({
    required this.label,
    required this.icon,
    required this.color,
    required this.softColor,
    required this.softColorDark,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color softColor;
  final Color softColorDark;
}
