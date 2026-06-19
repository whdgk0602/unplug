import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'unplug.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY,
        target_usage_minutes INTEGER NOT NULL DEFAULT 180,
        sleep_start_hour INTEGER NOT NULL DEFAULT 0,
        sleep_start_minute INTEGER NOT NULL DEFAULT 0,
        sleep_end_hour INTEGER NOT NULL DEFAULT 7,
        sleep_end_minute INTEGER NOT NULL DEFAULT 0,
        notification_enabled INTEGER NOT NULL DEFAULT 0,
        onboarding_done INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_records (
        date TEXT PRIMARY KEY,
        usage_minutes INTEGER NOT NULL DEFAULT 0,
        unused_minutes INTEGER NOT NULL DEFAULT 0,
        resource_earned INTEGER NOT NULL DEFAULT 0,
        target_snapshot INTEGER NOT NULL DEFAULT 180
      )
    ''');

    await db.execute('''
      CREATE TABLE world_state (
        id INTEGER PRIMARY KEY,
        theme_id TEXT NOT NULL DEFAULT 'island',
        stage INTEGER NOT NULL DEFAULT 0,
        total_resource INTEGER NOT NULL DEFAULT 0,
        last_growth_date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE growth_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        from_stage INTEGER NOT NULL,
        to_stage INTEGER NOT NULL
      )
    ''');

    // Insert default records
    await db.insert('settings', {
      'id': 1,
      'target_usage_minutes': 180,
      'sleep_start_hour': 0,
      'sleep_start_minute': 0,
      'sleep_end_hour': 7,
      'sleep_end_minute': 0,
      'notification_enabled': 0,
      'onboarding_done': 0,
    });

    await db.insert('world_state', {
      'id': 1,
      'theme_id': 'island',
      'stage': 0,
      'total_resource': 0,
      'last_growth_date': null,
    });
  }

  Future<void> initialize() async {
    try {
      await database;
    } catch (_) {
      // DB 파일 손상 등으로 열기 실패 시, 파일을 삭제하고 재생성해 영구 멈춤을 방지
      await _deleteDatabaseFile();
      _database = await _initDatabase();
    }
  }

  Future<void> _deleteDatabaseFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'unplug.db');
    await deleteDatabase(path);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
