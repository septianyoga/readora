import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database_helper.dart';

class BookmarkLocalDataSource {
  final DatabaseHelper _dbHelper;
  final _uuid = const Uuid();

  BookmarkLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const _tableName = 'bookmarks';

  Future<List<Map<String, dynamic>>> getByBookId(String bookId) async {
    final db = await _dbHelper.database;
    return db.query(
      _tableName,
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'page_number ASC',
    );
  }

  Future<Map<String, dynamic>?> findByBookIdAndPage({
    required String bookId,
    required int pageNumber,
  }) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _tableName,
      where: 'book_id = ? AND page_number = ?',
      whereArgs: [bookId, pageNumber],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> insert({
    required String bookId,
    required int pageNumber,
  }) async {
    final db = await _dbHelper.database;
    await db.insert(_tableName, {
      'id': _uuid.v4(),
      'book_id': bookId,
      'page_number': pageNumber,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deleteById(String id) async {
    final db = await _dbHelper.database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }
}