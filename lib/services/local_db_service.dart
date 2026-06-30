import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/daily_log.dart';

class LocalDbService {
  LocalDbService._();
  static final LocalDbService instance = LocalDbService._();

  static Database? _database;
  static const String _tableName = 'daily_logs';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('internlog.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        date TEXT NOT NULL,
        task_type TEXT NOT NULL,
        description TEXT NOT NULL,
        issues_found TEXT,
        image_url TEXT,
        local_image_path TEXT,
        is_synced INTEGER NOT NULL DEFAULT 1,
        approval_status TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertLog(DailyLog log) async {
    final db = await instance.database;
    await db.insert(
      _tableName,
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateLog(DailyLog log) async {
    final db = await instance.database;
    await db.update(
      _tableName,
      log.toMap(),
      where: 'id = ?',
      whereArgs: [log.id],
    );
  }

  Future<void> deleteLog(String id) async {
    final db = await instance.database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<DailyLog>> fetchLogs(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      _tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return result.map((json) => DailyLog.fromMap(json)).toList();
  }

  Future<List<DailyLog>> fetchUnsyncedLogs(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      _tableName,
      where: 'user_id = ? AND is_synced = 0',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return result.map((json) => DailyLog.fromMap(json)).toList();
  }

  Future<void> syncLogsWithSupabase(List<DailyLog> supabaseLogs, String userId) async {
    final db = await instance.database;
    final batch = db.batch();

    // Do not overwrite unsynced local logs. 
    // Insert/update logs from Supabase that are fully synced.
    for (final sLog in supabaseLogs) {
      final existing = await db.query(_tableName, where: 'id = ?', whereArgs: [sLog.id]);
      if (existing.isEmpty || existing.first['is_synced'] == 1) {
        batch.insert(
          _tableName,
          sLog.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    await batch.commit(noResult: true);
  }
}
