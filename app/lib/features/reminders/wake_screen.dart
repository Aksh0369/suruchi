import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/reminder_category.dart';

/// The full-screen view a firing alarm-style task opens into — matches the
/// "wake up" screen concept from the design spec. Not wired to any real
/// alarm yet (that's native AlarmManager work, still to come); reachable
/// today only via Settings' preview entry so the design can be reviewed.
class WakeScreen extends ConsumerWidget {
  const WakeScreen({super.key, required this.reminder});

  final Reminder reminder;

  String get _motivationalLine {
    switch (reminder.category) {
      case ReminderCategory.business:
        return 'Progress today, success tomorrow';
      case ReminderCategory.self:
        return 'Take care of yourself first';
      case ReminderCategory.seva:
        return 'Small acts, big meaning';
    }
  }

  String get _time {
    final dt = reminder.scheduledAt ?? DateTime.now();
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = reminder.category;
    const bg = Color(0xFFF3F6F8);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Purely decorative corner accents — kept tightly to the corners
          // (mostly off-screen) and non-interactive, so they never overlap
          // or intercept taps on the content regardless of screen size.
          IgnorePointer(
            child: Stack(
              children: [
                const Positioned(top: -90, left: -90, child: _Blob(size: 200, color: AppColors.brandDarkBackground)),
                Positioned(
                  top: -40,
                  left: 60,
                  child: _Blob(size: 90, color: AppColors.brandDarkBackground.withValues(alpha: 0.2)),
                ),
                const Positioned(bottom: -100, right: -100, child: _Blob(size: 220, color: AppColors.brandDarkBackground)),
                Positioned(
                  bottom: -30,
                  right: 50,
                  child: _Blob(size: 90, color: AppColors.brandDarkBackground.withValues(alpha: 0.2)),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandPrimary.withValues(alpha: 0.12),
                    ),
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brandDarkBackground,
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 44),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'TIME FOR YOUR TASK',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 3,
                      color: AppColors.brandDarkBackground.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    reminder.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 30,
                      color: AppColors.brandDarkBackground,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _motivationalLine,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.brandDarkBackground.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: category.color,
                          child: Icon(category.icon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.label.toUpperCase(),
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: category.color,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded,
                                    size: 16, color: AppColors.brandDarkBackground.withValues(alpha: 0.5)),
                                const SizedBox(width: 4),
                                Text(
                                  _time,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.brandDarkBackground,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionButton(
                        icon: Icons.close_rounded,
                        label: 'SNOOZE',
                        sublabel: 'in ${reminder.snoozeMinutes} minutes',
                        onTap: () {
                          if (reminder.scheduleMode == ScheduleMode.deadline) {
                            ref.read(reminderRepositoryProvider).upsert(reminder.copyWith(
                              scheduledAt: reminder.scheduledAt!
                                  .add(Duration(minutes: reminder.snoozeMinutes)),
                              updatedAt: DateTime.now(),
                            ));
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                      _ActionButton(
                        icon: Icons.check_rounded,
                        label: 'MARK AS DONE',
                        sublabel: '',
                        filled: true,
                        onTap: () {
                          ref.read(reminderRepositoryProvider).setCompleted(reminder.id, true);
                          Navigator.of(context).pop();
                        },
                      ),
                      _ActionButton(
                        icon: Icons.chevron_right_rounded,
                        label: 'SKIP',
                        sublabel: 'for now',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Container(width: 40, height: 1, color: AppColors.brandDarkBackground.withValues(alpha: 0.2)),
                  const SizedBox(height: 14),
                  Text(
                    'SMALL STEPS\nA BETTER YOU',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 2,
                      height: 1.6,
                      color: AppColors.brandDarkBackground.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final size = filled ? 84.0 : 68.0;
    return Column(
      children: [
        Material(
          color: filled ? AppColors.brandDarkBackground : Colors.black.withValues(alpha: 0.06),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                icon,
                color: filled ? Colors.white : AppColors.brandDarkBackground.withValues(alpha: 0.6),
                size: filled ? 34 : 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.brandDarkBackground,
          ),
        ),
        if (sublabel.isNotEmpty)
          Text(
            sublabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.brandDarkBackground.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }
}
