import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/book.dart';

/// Search query aktif pada Library screen.
final bookSearchQueryProvider = StateProvider<String>((ref) => '');

/// Opsi sorting aktif pada Library screen.
final bookSortOptionProvider =
    StateProvider<BookSortOption>((ref) => BookSortOption.recentlyAdded);

/// State utama daftar buku. Menggunakan [AsyncNotifier] supaya loading /
/// error state otomatis tertangani dan mudah dipanggil ulang (refresh)
/// setelah import atau delete buku.
class BookLibraryNotifier extends AsyncNotifier<List<Book>> {
  @override
  Future<List<Book>> build() async {
    final sortBy = ref.watch(bookSortOptionProvider);
    final repository = ref.watch(bookRepositoryProvider);
    return repository.getAllBooks(sortBy: sortBy);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> importBook(File pdfFile) async {
    final repository = ref.read(bookRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.importBook(pdfFile);
      final sortBy = ref.read(bookSortOptionProvider);
      return repository.getAllBooks(sortBy: sortBy);
    });
  }

  Future<void> deleteBook(String id) async {
    final repository = ref.read(bookRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.deleteBook(id);
      final sortBy = ref.read(bookSortOptionProvider);
      return repository.getAllBooks(sortBy: sortBy);
    });
  }
}

final bookLibraryProvider =
    AsyncNotifierProvider<BookLibraryNotifier, List<Book>>(
  BookLibraryNotifier.new,
);

/// Mengambil satu buku berdasarkan id, lengkap dengan progress terbaru.
/// Dipakai Book Detail screen. Di-invalidate setiap kali pengguna kembali
/// dari reader supaya progress yang ditampilkan selalu terbaru.
final bookByIdProvider =
    FutureProvider.family<Book?, String>((ref, bookId) async {
  final repository = ref.watch(bookRepositoryProvider);
  return repository.getBookById(bookId);
});

/// Daftar buku yang sudah difilter oleh search query. UI (Library screen)
/// cukup watch provider ini, tanpa perlu filter manual di widget.
final filteredBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final query = ref.watch(bookSearchQueryProvider).trim().toLowerCase();
  final booksAsync = ref.watch(bookLibraryProvider);

  if (query.isEmpty) return booksAsync;

  return booksAsync.whenData((books) {
    return books.where((book) {
      final title = book.title.toLowerCase();
      final author = (book.author ?? '').toLowerCase();
      return title.contains(query) || author.contains(query);
    }).toList();
  });
});
