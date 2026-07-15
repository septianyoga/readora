import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';

class SettingsLocalDataSource {
  final DatabaseHelper _dbHelper;

  SettingsLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const _tableName = 'settings';

  Future<Map<String, dynamic>?> getRow() async {
    final db = await _dbHelper.database;
    final rows = await db.query(_tableName, where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Selalu menulis baris lengkap (id = 1), jadi cukup pakai
  /// insert-with-replace tanpa perlu cek row lama dulu.
  Future<void> save({
    required bool darkMode,
    required double fontSize,
    required String defaultReadingMode,
  }) async {
    final db = await _dbHelper.database;
    await db.insert(
      _tableName,
      {
        'id': 1,
        'dark_mode': darkMode ? 1 : 0,
        'font_size': fontSize,
        'reading_direction': 'ltr',
        'default_reading_mode': defaultReadingMode,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}