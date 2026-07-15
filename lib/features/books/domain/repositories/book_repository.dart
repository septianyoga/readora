import 'dart:io';

import '../entities/book.dart';

/// Kontrak repository buku. Presentation layer (widget/provider) hanya
/// bergantung pada interface ini, tidak pernah langsung ke SQLite.
abstract class BookRepository {
  Future<List<Book>> getAllBooks({BookSortOption sortBy});

  Future<Book?> getBookById(String id);

  /// Mengimpor file PDF yang dipilih user:
  /// - copy file ke folder aplikasi
  /// - extract metadata dasar (jumlah halaman, ukuran file)
  /// - generate thumbnail cover
  /// - simpan record baru ke database
  Future<Book> importBook(File sourcePdfFile);

  Future<void> deleteBook(String id);

  Future<List<Book>> searchBooks(String query);
}
