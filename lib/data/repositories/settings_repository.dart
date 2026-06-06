import 'package:sqflite/sqflite.dart';
import 'package:project001/data/database/app_database.dart';
import 'package:project001/data/models/settings_model.dart';

class SettingsRepository {
  Future<SettingsModel> getSettings() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    if (maps.isEmpty) return const SettingsModel();
    return SettingsModel.fromMap(maps.first);
  }

  Future<void> saveSettings(SettingsModel settings) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTargetUsage(int minutes) async {
    final db = await AppDatabase.instance.database;
    await db.update('settings', {'target_usage_minutes': minutes}, where: 'id = ?', whereArgs: [1]);
  }

  Future<void> updateSleepWindow(int startHour, int startMinute, int endHour, int endMinute) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'settings',
      {
        'sleep_start_hour': startHour,
        'sleep_start_minute': startMinute,
        'sleep_end_hour': endHour,
        'sleep_end_minute': endMinute,
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<void> updateNotification(bool enabled) async {
    final db = await AppDatabase.instance.database;
    await db.update('settings', {'notification_enabled': enabled ? 1 : 0}, where: 'id = ?', whereArgs: [1]);
  }

  Future<void> setOnboardingDone() async {
    final db = await AppDatabase.instance.database;
    await db.update('settings', {'onboarding_done': 1}, where: 'id = ?', whereArgs: [1]);
  }

  Future<void> resetAll() async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'settings',
      const SettingsModel().toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}

