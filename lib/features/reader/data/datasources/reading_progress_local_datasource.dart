import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';

class ReadingProgressLocalDataSource {
  final DatabaseHelper _dbHelper;

  ReadingProgressLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const _tableName = 'reading_progress';

  Future<Map<String, dynamic>?> getByBookId(String bookId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _tableName,
      where: 'book_id = ?',
      whereArgs: [bookId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<List<Map<String, dynamic>>> getByBookIds(List<String> bookIds) async {
    if (bookIds.isEmpty) return [];
    final db = await _dbHelper.database;
    final placeholders = List.filled(bookIds.length, '?').join(',');
    return db.query(
      _tableName,
      where: 'book_id IN ($placeholders)',
      whereArgs: bookIds,
    );
  }

  /// Semua baris progress, dipakai untuk menghitung Reading Statistics
  /// (total halaman terbaca, total waktu baca, reading streak).
  Future<List<Map<String, dynamic>>> getAllRows() async {
    final db = await _dbHelper.database;
    return db.query(_tableName);
  }

  /// Menghapus seluruh riwayat baca (dipakai "Clear reading history" di
  /// Setting screen). Buku & bookmark/notes TIDAK ikut terhapus — hanya
  /// progress halaman & waktu bacanya yang di-reset.
  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete(_tableName);
  }

  /// Insert atau update baris progress untuk satu buku. Karena tabel
  /// `reading_progress` selalu 1 baris per buku, dipakai `id = bookId`
  /// supaya operasi ini idempotent (upsert) tanpa perlu SELECT dulu.
  Future<void> upsert({
    required String bookId,
    required int currentPage,
    required double percentage,
    required int lastOpenedAt,
    int? totalReadTime,
  }) async {
    final db = await _dbHelper.database;
    final existing = await getByBookId(bookId);

    final data = <String, Object?>{
      'id': bookId,
      'book_id': bookId,
      'current_page': currentPage,
      'percentage': percentage,
      'last_opened_at': lastOpenedAt,
      'total_read_time':
          totalReadTime ?? (existing?['total_read_time'] as int? ?? 0),
    };

    await db.insert(
      _tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> incrementReadingTime(String bookId, int seconds) async {
    final db = await _dbHelper.database;
    final existing = await getByBookId(bookId);

    if (existing == null) {
      // Belum ada baris progress sama sekali (kasus langka: reading time
      // dicatat sebelum halaman pertama sempat tersimpan). Buat baris
      // baru dengan current_page = 0.
      await db.insert(_tableName, {
        'id': bookId,
        'book_id': bookId,
        'current_page': 0,
        'percentage': 0.0,
        'last_opened_at': DateTime.now().millisecondsSinceEpoch,
        'total_read_time': seconds,
      });
      return;
    }

    final currentTotal = existing['total_read_time'] as int? ?? 0;
    await db.update(
      _tableName,
      {'total_read_time': currentTotal + seconds},
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
  }
}