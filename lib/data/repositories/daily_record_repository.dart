import 'package:sqflite/sqflite.dart';
import 'package:project001/core/utils/time_formatter.dart';
import 'package:project001/data/database/app_database.dart';
import 'package:project001/data/models/daily_record_model.dart';

class DailyRecordRepository {
  Future<DailyRecordModel?> getRecord(DateTime date) async {
    final db = await AppDatabase.instance.database;
    final key = TimeFormatter.toDateKey(date);
    final maps = await db.query('daily_records', where: 'date = ?', whereArgs: [key]);
    if (maps.isEmpty) return null;
    return DailyRecordModel.fromMap(maps.first);
  }

  Future<DailyRecordModel?> getTodayRecord() async {
    return getRecord(DateTime.now());
  }

  Future<void> upsertRecord(DailyRecordModel record) async {
    final db = await AppDatabase.instance.database;
    await db.insert('daily_records', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DailyRecordModel>> getRecordsForRange(DateTime start, DateTime end) async {
    final db = await AppDatabase.instance.database;
    final startKey = TimeFormatter.toDateKey(start);
    final endKey = TimeFormatter.toDateKey(end);
    final maps = await db.query(
      'daily_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startKey, endKey],
      orderBy: 'date ASC',
    );
    return maps.map(DailyRecordModel.fromMap).toList();
  }

  Future<List<DailyRecordModel>> getLast7Days() async {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 6));
    return getRecordsForRange(
      DateTime(start.year, start.month, start.day),
      DateTime(end.year, end.month, end.day),
    );
  }

  Future<List<DailyRecordModel>> getLast30Days() async {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 29));
    return getRecordsForRange(
      DateTime(start.year, start.month, start.day),
      DateTime(end.year, end.month, end.day),
    );
  }

  Future<int> getTotalUnusedMinutes() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery('SELECT SUM(unused_minutes) as total FROM daily_records');
    return (result.first['total'] as int?) ?? 0;
  }

  Future<void> deleteAllRecords() async {
    final db = await AppDatabase.instance.database;
    await db.delete('daily_records');
  }
}
