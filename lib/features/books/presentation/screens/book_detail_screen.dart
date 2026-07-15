import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_router.dart';
import '../../../bookmarks/presentation/providers/bookmark_providers.dart';
import '../../../notes/presentation/providers/note_providers.dart';
import '../providers/book_providers.dart';

class BookDetailScreen extends ConsumerWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  Future<void> _openReader(
    BuildContext context,
    WidgetRef ref, {
    required int startPage,
  }) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.reader,
      arguments: ReaderScreenArgs(bookId: bookId, startPage: startPage),
    );
    // Setelah kembali dari reader, refresh progress & bookmark supaya
    // Book Detail & Library selalu menampilkan data terbaru.
    ref.invalidate(bookByIdProvider(bookId));
    ref.invalidate(bookLibraryProvider);
    ref.invalidate(bookmarkListProvider(bookId));
  }

  Future<void> _openBookmarks(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.bookmarkList,
      arguments: bookId,
    );
    ref.invalidate(bookmarkListProvider(bookId));
  }

  Future<void> _openNotes(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).pushNamed(AppRoutes.notes, arguments: bookId);
    ref.invalidate(noteListProvider(bookId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookByIdProvider(bookId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Buku')),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Terjadi kesalahan: $error')),
        data: (book) {
          if (book == null) {
            return const Center(child: Text('Buku tidak ditemukan.'));
          }

          final theme = Theme.of(context);
          final hasProgress = book.currentPage > 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Hero(
                      tag: 'book-cover-${book.id}',
                      child: book.coverPath != null &&
                              File(book.coverPath!).existsSync()
                          ? Image.file(
                              File(book.coverPath!),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 48,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  book.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (book.author != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    book.author!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '${book.totalPages} halaman',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 16),
                if (hasProgress) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: (book.percentage / 100).clamp(0, 1),
                      ),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${book.percentage.toStringAsFixed(0)}% selesai · '
                    'Halaman ${book.currentPage} / ${book.totalPages}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _openReader(
                      context,
                      ref,
                      startPage: book.currentPage,
                    ),
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Continue Reading'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _openReader(context, ref, startPage: 1),
                    icon: const Icon(Icons.replay),
                    label: const Text('Start From Beginning'),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () =>
                        _openReader(context, ref, startPage: 1),
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Start Reading'),
                  ),
                ],
                const SizedBox(height: 24),
                Builder(
                  builder: (context) {
                    final bookmarkCount = ref
                            .watch(bookmarkListProvider(bookId))
                            .valueOrNull
                            ?.length ??
                        0;
                    final noteCount = ref
                            .watch(noteListProvider(bookId))
                            .valueOrNull
                            ?.length ??
                        0;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => _openBookmarks(context, ref),
                          icon: const Icon(Icons.bookmark_border),
                          label: Text(
                            bookmarkCount > 0
                                ? 'Bookmarks ($bookmarkCount)'
                                : 'Bookmarks',
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton.icon(
                          onPressed: () => _openNotes(context, ref),
                          icon: const Icon(Icons.notes_outlined),
                          label: Text(
                            noteCount > 0 ? 'Notes ($noteCount)' : 'Notes',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}