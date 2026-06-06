import 'package:sqflite/sqflite.dart';
import 'package:project001/core/constants/app_constants.dart';
import 'package:project001/data/database/app_database.dart';
import 'package:project001/data/models/growth_history_model.dart';
import 'package:project001/data/models/world_state_model.dart';

class WorldRepository {
  Future<WorldStateModel> getWorldState() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query('world_state', where: 'id = ?', whereArgs: [1]);
    if (maps.isEmpty) return const WorldStateModel();
    return WorldStateModel.fromMap(maps.first);
  }

  Future<void> saveWorldState(WorldStateModel state) async {
    final db = await AppDatabase.instance.database;
    await db.insert('world_state', state.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<WorldStateModel> addResource(int amount, String date) async {
    final db = await AppDatabase.instance.database;
    final current = await getWorldState();

    int newTotal = current.totalResource + amount;
    int newStage = current.stage;
    final List<GrowthHistoryModel> growthEvents = [];

    while (newStage < AppConstants.maxStage) {
      final required = AppConstants.resourceRequiredForStage(newStage);
      final thresholdTotal = AppConstants.totalResourceForStage(newStage) + required;
      if (newTotal >= thresholdTotal) {
        growthEvents.add(GrowthHistoryModel(date: date, fromStage: newStage, toStage: newStage + 1));
        newStage++;
      } else {
        break;
      }
    }

    final newState = current.copyWith(
      stage: newStage,
      totalResource: newTotal,
      lastGrowthDate: growthEvents.isNotEmpty ? date : current.lastGrowthDate,
    );

    await saveWorldState(newState);

    for (final event in growthEvents) {
      await db.insert('growth_history', event.toMap());
    }

    return newState;
  }

  Future<List<GrowthHistoryModel>> getGrowthHistory() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query('growth_history', orderBy: 'date DESC');
    return maps.map(GrowthHistoryModel.fromMap).toList();
  }

  Future<void> resetWorld() async {
    final db = await AppDatabase.instance.database;
    await db.insert('world_state', const WorldStateModel().toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await db.delete('growth_history');
  }
}
