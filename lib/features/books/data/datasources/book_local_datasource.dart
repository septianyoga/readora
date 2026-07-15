import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database_helper.dart';
import '../models/book_model.dart';

/// Sumber data lokal untuk fitur buku.
///
/// Menggabungkan dua tanggung jawab yang berkaitan erat:
/// 1. Operasi file system (copy PDF ke folder aplikasi, generate cover).
/// 2. Query mentah ke tabel `books` di SQLite.
///
/// [BookRepositoryImpl] memakai class ini tanpa perlu tahu detail path
/// atau SQL yang dipakai.
class BookLocalDataSource {
  final DatabaseHelper _dbHelper;
  final _uuid = const Uuid();

  BookLocalDataSource({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const _tableName = 'books';

  // ---------------------------------------------------------------------
  // File system operations
  // ---------------------------------------------------------------------

  Future<Directory> get _booksDir async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'books'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> get _coversDir async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, 'covers'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copy file PDF sumber ke folder aplikasi dengan nama unik (UUID),
  /// supaya tidak bentrok dengan file lain dan tidak bergantung pada
  /// lokasi asli file (yang bisa saja dihapus user setelah import).
  Future<File> copyPdfToAppStorage(File sourceFile, String bookId) async {
    final dir = await _booksDir;
    final destPath = p.join(dir.path, '$bookId.pdf');
    return sourceFile.copy(destPath);
  }

  /// Render halaman pertama PDF sebagai thumbnail cover (PNG) dan
  /// simpan ke folder `covers/`. Mengembalikan null jika gagal
  /// (misal PDF corrupt) supaya proses import tetap bisa lanjut
  /// tanpa cover.
  Future<String?> generateCoverThumbnail(File pdfFile, String bookId) async {
    try {
      final document = await PdfDocument.openFile(pdfFile.path);
      final page = await document.getPage(1);
      final pageImage = await page.render(
        width: page.width * 0.6,
        height: page.height * 0.6,
        format: PdfPageImageFormat.png,
      );
      await page.close();
      await document.close();

      if (pageImage == null) return null;

      final dir = await _coversDir;
      final coverPath = p.join(dir.path, '$bookId.png');
      final coverFile = File(coverPath);
      await coverFile.writeAsBytes(pageImage.bytes);
      return coverPath;
    } catch (_) {
      return null;
    }
  }

  Future<int> getTotalPages(File pdfFile) async {
    final document = await PdfDocument.openFile(pdfFile.path);
    final pageCount = document.pagesCount;
    await document.close();
    return pageCount;
  }

  String newBookId() => _uuid.v4();

  // ---------------------------------------------------------------------
  // SQLite operations
  // ---------------------------------------------------------------------

  Future<List<BookModel>> getAllBooks() async {
    final db = await _dbHelper.database;
    final rows = await db.query(_tableName, orderBy: 'updated_at DESC');
    return rows.map(BookModel.fromMap).toList();
  }

  Future<BookModel?> getBookById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BookModel.fromMap(rows.first);
  }

  Future<void> insertBook(BookModel book) async {
    final db = await _dbHelper.database;
    await db.insert(
      _tableName,
      book.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBook(String id) async {
    final db = await _dbHelper.database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BookModel>> searchBooks(String query) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      _tableName,
      where: 'title LIKE ? OR author LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );
    return rows.map(BookModel.fromMap).toList();
  }
}
