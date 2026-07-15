import '../entities/bookmark.dart';

abstract class BookmarkRepository {
  /// Semua bookmark untuk satu buku, terurut dari halaman terkecil.
  Future<List<Bookmark>> getBookmarksForBook(String bookId);

  /// Menambah bookmark baru jika halaman ini belum di-bookmark,
  /// atau menghapusnya jika sudah ada (dipakai tombol bookmark di toolbar
  /// reader, yang berfungsi sebagai toggle).
  Future<void> toggleBookmark({
    required String bookId,
    required int pageNumber,
  });

  Future<void> deleteBookmark(String id);
}