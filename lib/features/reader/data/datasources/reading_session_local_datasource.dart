import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database_helper.dart';

class ReadingSessionLocalDataSource {
  final DatabaseHelper _dbHelper;
  final _uuid = const Uuid();

  ReadingSessionLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const _tableName = 'reading_sessions';

  Future<void> insert({
    required String bookId,
    required int startedAt,
    required int endedAt,
    required int durationSeconds,
    required int startPage,
    required int endPage,
    required int pagesRead,
  }) async {
    final db = await _dbHelper.database;
    await db.insert(_tableName, {
      'id': _uuid.v4(),
      'book_id': bookId,
      'started_at': startedAt,
      'ended_at': endedAt,
      'duration_seconds': durationSeconds,
      'start_page': startPage,
      'end_page': endPage,
      'pages_read': pagesRead,
    });
  }

  /// Semua sesi yang `started_at`-nya jatuh di antara [from] dan [to]
  /// (epoch millis, inclusive-exclusive), terurut dari yang terbaru.
  Future<List<Map<String, dynamic>>> getSessionsBetween({
    required int from,
    required int to,
  }) async {
    final db = await _dbHelper.database;
    return db.query(
      _tableName,
      where: 'started_at >= ? AND started_at < ?',
      whereArgs: [from, to],
      orderBy: 'started_at DESC',
    );
  }

  /// Seluruh sesi sepanjang waktu — dipakai untuk hal-hal yang sifatnya
  /// lifetime dan tidak seharusnya berubah tergantung filter periode,
  /// seperti Achievements dan Reading Streak.
  Future<List<Map<String, dynamic>>> getAllSessions() async {
    final db = await _dbHelper.database;
    return db.query(_tableName, orderBy: 'started_at DESC');
  }

  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete(_tableName);
  }
}