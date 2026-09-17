import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/database_provider.dart';
import '../../core/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('THEME', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          themeModeAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (err, _) => Text('Could not load theme setting: $err'),
            data: (currentMode) => RadioGroup<ThemeMode>(
              groupValue: currentMode,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(settingsRepositoryProvider).setThemeMode(mode);
                }
              },
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Follow system'),
                    value: ThemeMode.system,
                  ),
                  RadioListTile<ThemeMode>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Light'),
                    value: ThemeMode.light,
                  ),
                  RadioListTile<ThemeMode>(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Dark'),
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
