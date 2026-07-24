import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';

class ReadingGoalLocalDataSource {
  final DatabaseHelper _dbHelper;

  ReadingGoalLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const _tableName = 'reading_goal';

  Future<Map<String, dynamic>?> getRow() async {
    final db = await _dbHelper.database;
    final rows = await db.query(_tableName, where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> save({
    required String goalType,
    required double targetValue,
  }) async {
    final db = await _dbHelper.database;
    await db.insert(
      _tableName,
      {'id': 1, 'goal_type': goalType, 'target_value': targetValue},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete() async {
    final db = await _dbHelper.database;
    await db.delete(_tableName, where: 'id = 1');
  }
}