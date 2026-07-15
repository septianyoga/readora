import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton helper yang bertanggung jawab membuka koneksi SQLite
/// dan membuat seluruh skema database aplikasi.
///
/// Skema mengikuti spesifikasi:
/// - books
/// - reading_progress
/// - bookmarks
/// - notes
/// - settings
///
/// Catatan: pada Phase 1 hanya tabel `books` yang benar-benar dipakai oleh
/// fitur (Library screen). Tabel lain sudah dibuat sejak awal supaya
/// migrasi di phase berikutnya tidak perlu mengubah versi database.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'bookreader.db';
  static const _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final path = join(documentsDir.path, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: (db) async {
        // Aktifkan foreign key constraint di SQLite.
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT,
        cover_path TEXT,
        pdf_path TEXT NOT NULL,
        total_pages INTEGER NOT NULL DEFAULT 0,
        file_size INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE reading_progress (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        current_page INTEGER NOT NULL DEFAULT 0,
        percentage REAL NOT NULL DEFAULT 0,
        last_opened_at INTEGER,
        total_read_time INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE bookmarks (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        page_number INTEGER NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        dark_mode INTEGER NOT NULL DEFAULT 0,
        font_size REAL NOT NULL DEFAULT 16,
        reading_direction TEXT NOT NULL DEFAULT 'ltr',
        default_reading_mode TEXT NOT NULL DEFAULT 'light'
      )
    ''');

    batch.execute('''
      CREATE INDEX idx_reading_progress_book_id ON reading_progress (book_id)
    ''');
    batch.execute('''
      CREATE INDEX idx_bookmarks_book_id ON bookmarks (book_id)
    ''');
    batch.execute('''
      CREATE INDEX idx_notes_book_id ON notes (book_id)
    ''');

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}