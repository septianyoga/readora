import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_router.dart';
import '../../domain/entities/bookmark.dart';
import '../providers/bookmark_providers.dart';

class BookmarkListScreen extends ConsumerWidget {
  final String bookId;

  const BookmarkListScreen({super.key, required this.bookId});

  Future<void> _openAtPage(
    BuildContext context,
    WidgetRef ref,
    int page,
  ) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.reader,
      arguments: ReaderScreenArgs(bookId: bookId, startPage: page),
    );
    ref.invalidate(bookmarkListProvider(bookId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkListProvider(bookId));

    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: bookmarksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Terjadi kesalahan: $error')),
        data: (bookmarks) {
          if (bookmarks.isEmpty) {
            return _EmptyBookmarks(bookId: bookId);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookmarks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index];
              return _BookmarkTile(
                bookmark: bookmark,
                onTap: () => _openAtPage(context, ref, bookmark.pageNumber),
                onDelete: () =>
                    ref.read(bookmarkListProvider(bookId).notifier).remove(
                          bookmark.id,
                        ),
              );
            },
          );
        },
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BookmarkTile({
    required this.bookmark,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.bookmark),
        title: Text('Page ${bookmark.pageNumber}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Hapus bookmark',
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _EmptyBookmarks extends StatelessWidget {
  final String bookId;

  const _EmptyBookmarks({required this.bookId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('Belum ada bookmark', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Tekan ikon bookmark di reader saat membaca untuk menyimpan halaman.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}