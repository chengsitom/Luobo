import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/download_record.dart';

/// 离线下载记录的独立 SQLite 存储。
///
/// 与 [LibraryDatabaseService] 刻意分库：曲库会随服务器切换被整体清空重建，
/// 而下载文件是用户花流量换来的稀缺资源，必须能按 serverId 独立保留。
/// 单表、记录量级 = 用户下载过的歌（通常几百到几千），无需分页。
class DownloadDatabaseService {
  static const String _dbName = 'musly_offline.db';
  static const int _dbVersion = 1;
  static const String _table = 'download_records';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    return openDatabase(
      join(databasesPath, _dbName),
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            songId TEXT PRIMARY KEY,
            serverId TEXT NOT NULL DEFAULT '',
            songJson TEXT NOT NULL,
            fileName TEXT NOT NULL,
            suffix TEXT NOT NULL DEFAULT 'mp3',
            bytes INTEGER NOT NULL DEFAULT 0,
            downloadedAt INTEGER NOT NULL,
            source TEXT NOT NULL DEFAULT 'manual',
            status TEXT NOT NULL DEFAULT 'complete'
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_download_server ON $_table(serverId)',
        );
      },
    );
  }

  Future<List<DownloadRecord>> getAll() async {
    final db = await database;
    final maps = await db.query(_table);
    return maps.map(DownloadRecord.fromMap).toList();
  }

  Future<DownloadRecord?> get(String songId) async {
    final db = await database;
    final maps = await db.query(_table, where: 'songId = ?', whereArgs: [songId]);
    if (maps.isEmpty) return null;
    return DownloadRecord.fromMap(maps.first);
  }

  Future<void> upsert(DownloadRecord record) async {
    final db = await database;
    await db.insert(
      _table,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertMany(List<DownloadRecord> records) async {
    if (records.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final record in records) {
        batch.insert(
          _table,
          record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> delete(String songId) async {
    final db = await database;
    await db.delete(_table, where: 'songId = ?', whereArgs: [songId]);
  }

  Future<void> deleteMany(List<String> songIds) async {
    if (songIds.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final id in songIds) {
        batch.delete(_table, where: 'songId = ?', whereArgs: [id]);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> deleteByServer(String serverId) async {
    final db = await database;
    await db.delete(_table, where: 'serverId = ?', whereArgs: [serverId]);
  }

  Future<void> clear() async {
    final db = await database;
    await db.delete(_table);
  }
}
