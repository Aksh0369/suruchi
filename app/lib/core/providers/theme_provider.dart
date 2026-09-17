import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'database_provider.dart';

part 'theme_provider.g.dart';

@riverpod
Stream<ThemeMode> themeMode(Ref ref) {
  return ref.watch(settingsRepositoryProvider).watchThemeMode();
}
