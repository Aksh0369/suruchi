import 'package:flutter/material.dart';

import '../database/app_database.dart';

const _themeModeKey = 'theme_mode';

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Stream<ThemeMode> watchThemeMode() {
    final query = _db.select(_db.appSettings)..where((t) => t.key.equals(_themeModeKey));
    return query.watchSingleOrNull().map((row) => _parseThemeMode(row?.value));
  }

  Future<void> setThemeMode(ThemeMode mode) {
    return _db.into(_db.appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: _themeModeKey, value: mode.name),
    );
  }

  ThemeMode _parseThemeMode(String? value) {
    return ThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => ThemeMode.system,
    );
  }
}
