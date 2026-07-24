import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton helper yang bertanggung jawab membuka koneksi SQLite
/// dan membuat seluruh skema database aplikasi.
///
/// PENTING soal migrasi: `onCreate` HANYA jalan saat file database belum
/// ada sama sekali (install baru). Begitu app pernah dijalankan sekali
/// di sebuah device, skema yang sudah dibuat itu "membeku" — perubahan
/// apa pun ke `_onCreate` setelahnya TIDAK akan terasa di device yang
/// sudah pernah install, walaupun kode aplikasinya sudah di-update.
/// Supaya tabel/kolom baru ikut muncul di database yang sudah ada, kita
/// WAJIB naikkan [_dbVersion] dan tambahkan langkah migrasinya di
/// [_onUpgrade]. Jangan lagi cuma edit `_onCreate` untuk perubahan skema
/// berikutnya.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _dbName = 'bookreader.db';
  static const _dbVersion = 2;

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
      onUpgrade: _onUpgrade,
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

    // Log satu baris per sesi baca (dari buka reader sampai ditutup).
    // Ditambahkan untuk dashboard Statistics: tanpa ini, kita cuma punya
    // angka akumulasi per buku (reading_progress.total_read_time) yang
    // tidak bisa dipecah per hari/minggu/bulan — padahal trend chart,
    // activity calendar (heatmap), dan reading habits semuanya butuh
    // riwayat per sesi, bukan cuma total.
    batch.execute('''
      CREATE TABLE reading_sessions (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        ended_at INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        start_page INTEGER NOT NULL,
        end_page INTEGER NOT NULL,
        pages_read INTEGER NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');

    // Target baca user (Reading Goal di Statistics). Satu baris aktif
    // saja (id = 1) sesuai pola tabel `settings`.
    batch.execute('''
      CREATE TABLE reading_goal (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        goal_type TEXT NOT NULL,
        target_value REAL NOT NULL
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
    batch.execute('''
      CREATE INDEX idx_reading_sessions_book_id ON reading_sessions (book_id)
    ''');
    batch.execute('''
      CREATE INDEX idx_reading_sessions_started_at ON reading_sessions (started_at)
    ''');

    await batch.commit(noResult: true);
  }

  /// Migrasi untuk device yang SUDAH punya database dari versi
  /// sebelumnya. Semua langkah di sini ditulis idempotent (`IF NOT
  /// EXISTS` / cek kolom dulu sebelum `ALTER TABLE`) supaya aman
  /// dijalankan dari versi lama manapun tanpa perlu tahu persis kolom
  /// apa saja yang sudah ada di device itu.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Device lama mungkin sudah punya tabel `settings` tapi belum
      // punya kolom ini (ditambahkan setelah Phase 4).
      await _ensureColumn(
        db,
        table: 'settings',
        column: 'default_reading_mode',
        columnDdl: "TEXT NOT NULL DEFAULT 'light'",
      );

      await db.execute('''
        CREATE TABLE IF NOT EXISTS reading_sessions (
          id TEXT PRIMARY KEY,
          book_id TEXT NOT NULL,
          started_at INTEGER NOT NULL,
          ended_at INTEGER NOT NULL,
          duration_seconds INTEGER NOT NULL,
          start_page INTEGER NOT NULL,
          end_page INTEGER NOT NULL,
          pages_read INTEGER NOT NULL,
          FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS reading_goal (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          goal_type TEXT NOT NULL,
          target_value REAL NOT NULL
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_reading_sessions_book_id
        ON reading_sessions (book_id)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_reading_sessions_started_at
        ON reading_sessions (started_at)
      ''');
    }

    // Migrasi versi berikutnya ditambahkan di sini sebagai:
    // if (oldVersion < 3) { ... }
  }

  Future<void> _ensureColumn(
    Database db, {
    required String table,
    required String column,
    required String columnDdl,
  }) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final alreadyExists = info.any((row) => row['name'] == column);
    if (!alreadyExists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $columnDdl');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}