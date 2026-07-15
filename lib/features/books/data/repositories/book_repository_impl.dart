import 'dart:io';

import '../../../reader/data/datasources/reading_progress_local_datasource.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_local_datasource.dart';
import '../models/book_model.dart';

class BookRepositoryImpl implements BookRepository {
  final BookLocalDataSource _localDataSource;
  final ReadingProgressLocalDataSource _progressDataSource;

  BookRepositoryImpl({
    BookLocalDataSource? localDataSource,
    ReadingProgressLocalDataSource? progressDataSource,
  })  : _localDataSource = localDataSource ?? BookLocalDataSource(),
        _progressDataSource =
            progressDataSource ?? ReadingProgressLocalDataSource();

  /// Melengkapi entity [Book] dengan data dari `reading_progress` (current
  /// page, percentage, last opened) memakai satu query batch, supaya
  /// Library screen tidak melakukan N+1 query ke tabel progress.
  Future<List<Book>> _attachProgress(List<BookModel> models) async {
    final ids = models.map((m) => m.id).toList();
    final progressRows = await _progressDataSource.getByBookIds(ids);
    final progressByBookId = {
      for (final row in progressRows) row['book_id'] as String: row,
    };

    return models.map((model) {
      final row = progressByBookId[model.id];
      if (row == null) return model.toEntity();

      final lastOpenedMillis = row['last_opened_at'] as int?;
      return model.toEntity(
        currentPage: row['current_page'] as int? ?? 0,
        percentage: (row['percentage'] as num?)?.toDouble() ?? 0,
        lastOpenedAt: lastOpenedMillis != null
            ? DateTime.fromMillisecondsSinceEpoch(lastOpenedMillis)
            : null,
      );
    }).toList();
  }

  @override
  Future<List<Book>> getAllBooks({
    BookSortOption sortBy = BookSortOption.recentlyAdded,
  }) async {
    final models = await _localDataSource.getAllBooks();
    final books = await _attachProgress(models);
    return _sortBooks(books, sortBy);
  }

  List<Book> _sortBooks(List<Book> books, BookSortOption sortBy) {
    final sorted = [...books];
    switch (sortBy) {
      case BookSortOption.title:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case BookSortOption.recentlyAdded:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case BookSortOption.lastRead:
        sorted.sort((a, b) {
          final aTime = a.lastOpenedAt ?? a.createdAt;
          final bTime = b.lastOpenedAt ?? b.createdAt;
          return bTime.compareTo(aTime);
        });
        break;
    }
    return sorted;
  }

  @override
  Future<Book?> getBookById(String id) async {
    final model = await _localDataSource.getBookById(id);
    if (model == null) return null;
    final withProgress = await _attachProgress([model]);
    return withProgress.first;
  }

  @override
  Future<Book> importBook(File sourcePdfFile) async {
    final id = _localDataSource.newBookId();

    // 1. Copy PDF ke folder aplikasi supaya tidak bergantung pada file asal.
    final storedPdf = await _localDataSource.copyPdfToAppStorage(
      sourcePdfFile,
      id,
    );

    // 2. Extract metadata dasar.
    final totalPages = await _localDataSource.getTotalPages(storedPdf);
    final fileSize = await storedPdf.length();

    // 3. Generate cover thumbnail (boleh gagal / null).
    final coverPath = await _localDataSource.generateCoverThumbnail(
      storedPdf,
      id,
    );

    // 4. Judul default diambil dari nama file ASLI yang dipilih user
    //    (bukan dari `storedPdf`, karena nama file itu sudah diganti jadi
    //    UUID saat di-copy ke storage aplikasi). Underscore/dash diganti
    //    spasi supaya enak dibaca & tetap match saat di-search.
    final originalFileName = sourcePdfFile.uri.pathSegments.last;
    final title = originalFileName
        .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim();

    final now = DateTime.now();
    final model = BookModel(
      id: id,
      title: title,
      author: null,
      coverPath: coverPath,
      pdfPath: storedPdf.path,
      totalPages: totalPages,
      fileSize: fileSize,
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );

    await _localDataSource.insertBook(model);
    return model.toEntity();
  }

  @override
  Future<void> deleteBook(String id) async {
    final model = await _localDataSource.getBookById(id);
    await _localDataSource.deleteBook(id);

    // Best-effort cleanup file PDF & cover. Kegagalan di sini tidak
    // dianggap fatal karena record database sudah terhapus.
    if (model != null) {
      final pdfFile = File(model.pdfPath);
      if (await pdfFile.exists()) {
        await pdfFile.delete();
      }
      if (model.coverPath != null) {
        final coverFile = File(model.coverPath!);
        if (await coverFile.exists()) {
          await coverFile.delete();
        }
      }
    }
  }

  @override
  Future<List<Book>> searchBooks(String query) async {
    final models = await _localDataSource.searchBooks(query);
    return _attachProgress(models);
  }
}