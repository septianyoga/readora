import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database_helper.dart';

class NoteLocalDataSource {
  final DatabaseHelper _dbHelper;
  final _uuid = const Uuid();

  NoteLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const _tableName = 'notes';

  Future<List<Map<String, dynamic>>> getByBookId(String bookId) async {
    final db = await _dbHelper.database;
    return db.query(
      _tableName,
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'page_number ASC',
    );
  }

  Future<void> insert({
    required String bookId,
    required int pageNumber,
    required String content,
  }) async {
    final db = await _dbHelper.database;
    await db.insert(_tableName, {
      'id': _uuid.v4(),
      'book_id': bookId,
      'page_number': pageNumber,
      'content': content,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> update({
    required String id,
    required String content,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      _tableName,
      {'content': content},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteById(String id) async {
    final db = await _dbHelper.database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }
}