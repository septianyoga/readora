import '../../domain/entities/bookmark.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../datasources/bookmark_local_datasource.dart';

class BookmarkRepositoryImpl implements BookmarkRepository {
  final BookmarkLocalDataSource _localDataSource;

  BookmarkRepositoryImpl({BookmarkLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? BookmarkLocalDataSource();

  Bookmark _mapRow(Map<String, dynamic> row) {
    return Bookmark(
      id: row['id'] as String,
      bookId: row['book_id'] as String,
      pageNumber: row['page_number'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }

  @override
  Future<List<Bookmark>> getBookmarksForBook(String bookId) async {
    final rows = await _localDataSource.getByBookId(bookId);
    return rows.map(_mapRow).toList();
  }

  @override
  Future<void> toggleBookmark({
    required String bookId,
    required int pageNumber,
  }) async {
    final existing = await _localDataSource.findByBookIdAndPage(
      bookId: bookId,
      pageNumber: pageNumber,
    );

    if (existing != null) {
      await _localDataSource.deleteById(existing['id'] as String);
    } else {
      await _localDataSource.insert(bookId: bookId, pageNumber: pageNumber);
    }
  }

  @override
  Future<void> deleteBookmark(String id) async {
    await _localDataSource.deleteById(id);
  }
}