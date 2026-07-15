import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/bookmark.dart';

/// Daftar bookmark untuk satu buku. Dipakai baik oleh Reader (untuk tahu
/// apakah halaman saat ini sudah di-bookmark) maupun Bookmark List screen.
class BookmarkListNotifier extends FamilyAsyncNotifier<List<Bookmark>, String> {
  @override
  Future<List<Bookmark>> build(String bookId) async {
    final repository = ref.watch(bookmarkRepositoryProvider);
    return repository.getBookmarksForBook(bookId);
  }

  Future<void> _refresh() async {
    final repository = ref.read(bookmarkRepositoryProvider);
    state = await AsyncValue.guard(
      () => repository.getBookmarksForBook(arg),
    );
  }

  /// Toggle bookmark untuk halaman tertentu — dipanggil dari toolbar Reader.
  Future<void> toggleForPage(int pageNumber) async {
    final repository = ref.read(bookmarkRepositoryProvider);
    await repository.toggleBookmark(bookId: arg, pageNumber: pageNumber);
    await _refresh();
  }

  Future<void> remove(String bookmarkId) async {
    final repository = ref.read(bookmarkRepositoryProvider);
    await repository.deleteBookmark(bookmarkId);
    await _refresh();
  }
}

final bookmarkListProvider =
    AsyncNotifierProvider.family<BookmarkListNotifier, List<Bookmark>, String>(
  BookmarkListNotifier.new,
);

/// Helper sederhana: apakah `page` ada di daftar bookmark buku `bookId`.
/// Dipakai Reader toolbar untuk menentukan ikon bookmark terisi/tidak.
bool isPageBookmarked(List<Bookmark> bookmarks, int page) {
  return bookmarks.any((b) => b.pageNumber == page);
}